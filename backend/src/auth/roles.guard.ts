import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UsersService } from 'src/users/user.service';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private userService: UsersService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRole = this.reflector.get<string[]>(
      'role',
      context.getHandler(),
    );
    if (!requiredRole) return true; // Nếu API không yêu cầu role, cho phép truy cập

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    // Nếu không có user hoặc role không khớp, từ chối truy cập
    if (!user || user.role !== requiredRole) {
      throw new ForbiddenException('Access denied: You do not have permission');
    }

    return requiredRole.includes(user.role);
  }
}
