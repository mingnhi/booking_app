import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { Users, UsersDocument } from './users.schema';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(Users.name) private readonly userModel: Model<UsersDocument>,
  ) {}

  // Tạo một người dùng mới
  async create(userData: {
    email: string;
    password: string;
    full_name: string;
    phone_number: string;
    role: string;
  }): Promise<UsersDocument> {
    const { email, password, full_name, phone_number, role } = userData;

    // Kiểm tra xem email đã tồn tại chưa
    const existingUser = await this.userModel.findOne({ email });
    if (existingUser) {
      throw new BadRequestException('Email đã được sử dụng');
    }

    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new this.userModel({
      email,
      password: hashedPassword,
      full_name,
      phone_number,
      role,
    });

    return newUser.save();
  }

  // Tìm người dùng theo email
  async findByEmail(email: string): Promise<UsersDocument | null> {
    return this.userModel.findOne({ email }).exec();
  }

  // Lấy danh sách tất cả người dùng
  async findAll(): Promise<UsersDocument[]> {
    return this.userModel.find().exec();
  }

  // Xác thực người dùng dựa trên email và mật khẩu
  async validateUser(email: string, password: string): Promise<UsersDocument> {
    console.log(' Email nhận được:', email);
    const user = await this.findByEmail(email);
    console.log(' User trong DB:', user);
    if (!user) {
      throw new BadRequestException('Thông tin đăng nhập không hợp lệ');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    console.log(' Mật khẩu đúng?', isPasswordValid);
    if (!isPasswordValid) {
      throw new BadRequestException('Thông tin đăng nhập không hợp lệ');
    }

    return user;
  }

  // Tìm người dùng theo ID
  async findById(id: string): Promise<UsersDocument | null> {
    return this.userModel.findById(id).exec();
  }

  // Lưu refresh token vào cơ sở dữ liệu
  async saveRefreshToken(
    refreshToken: string,
    userId: string,
  ): Promise<UsersDocument> {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('Người dùng không tồn tại');
    }

    const hashRefreshToken = await bcrypt.hash(refreshToken, 10);
    user.refresh_token = hashRefreshToken;
    return user.save();
  }

  // Xác minh refresh token
  async verifyRefreshToken(
    refreshToken: string,
  ): Promise<UsersDocument | null> {
    const users = await this.userModel.find().exec();
    for (const user of users) {
      if (user.refresh_token) {
        const isValid = await bcrypt.compare(refreshToken, user.refresh_token);
        if (isValid) {
          return user;
        }
      }
    }
    return null;
  }

  // Cập nhật thông tin người dùng
  async update(id: string, updateData: Partial<Users>): Promise<UsersDocument> {
    const user = await this.findById(id);
    if (!user) {
      throw new NotFoundException('Người dùng không tồn tại');
    }

    Object.assign(user, updateData);
    return user.save();
  }

  // Xóa người dùng
  async delete(id: string): Promise<void> {
    const user = await this.findById(id);
    if (!user) {
      throw new NotFoundException('Người dùng không tồn tại');
    }

    await user.deleteOne();
  }
}
