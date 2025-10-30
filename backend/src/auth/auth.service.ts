import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from 'src/users/user.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { Users, UsersDocument } from 'src/users/users.schema'; // import User schema
import * as bcrypt from 'bcrypt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

@Injectable()
export class AuthService {
  constructor(
    private readonly userService: UsersService,
    private readonly jwtService: JwtService,
    @InjectModel(Users.name) private readonly userModel: Model<UsersDocument>, // Inject Mongoose model
  ) {}

  async register(registerDto: RegisterDto): Promise<void> {
    const { email, password, full_name, phone_number, role } = registerDto;

    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) {
      throw new BadRequestException('Email already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new this.userModel({
      email,
      password: hashedPassword,
      full_name,
      phone_number,
      role,
    });

    await newUser.save(); // Save the new user to MongoDB
  }

  async login(
    loginDto: LoginDto,
  ): Promise<{ user: Users; accessToken: string; refresh_token: string }> {
    const user = await this.userService.validateUser(
      loginDto.email,
      loginDto.password,
    );

    const payload = { email: user.email, sub: user.id };
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

    // Save the refresh token to the user document in MongoDB
    user.refresh_token = refreshToken;
    await user.save();

    return {
      user,
      accessToken: this.jwtService.sign(payload),
      refresh_token: refreshToken,
    };
  }

  async verifyRefreshToken(refreshToken: string): Promise<Users> {
    const user = await this.userModel.findOne({ refresh_token: refreshToken });
    if (!user) {
      throw new UnauthorizedException('Invalid refresh token');
    }
    return user;
  }
}
