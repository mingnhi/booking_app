import { Controller, Post, Body, UseGuards, Get, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { UsersService } from 'src/users/user.service';

interface RequestWithUser extends Request {
  user?: { userId: string }; // Vì MongoDB dùng string (ObjectId)
}

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly userService: UsersService,
  ) {}

  @Post('register')
  async register(@Body() registerDto: RegisterDto) {
    await this.authService.register(registerDto);
    return { message: 'User registered successfully' };
  }

  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('refresh')
  async refresh(@Body() body: { refreshToken: string }) {
    const user = await this.authService.verifyRefreshToken(body.refreshToken);
    return this.authService.login({ email: user.email, password: '' }); // Bỏ qua password vì đã xác thực bằng refreshToken
  }

  // @Post('logout')
  // @UseGuards(JwtAuthGuard)
  // async logout(@Req() req: RequestWithUser) {
  //   const user = req.user;
  //   return this.authService.logout(user.userId);
  // }

  @UseGuards(JwtAuthGuard)
  @Get('profile')
  async getProfile(@Req() req: RequestWithUser) {
    const userId = req.user?.userId;
    if (!userId) {
      throw new Error('User ID not found in request');
    }
    const user = await this.userService.findById(userId);
    return user;
  }
}
