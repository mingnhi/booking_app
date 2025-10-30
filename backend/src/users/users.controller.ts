import {
  Body,
  Controller,
  Param,
  Put,
  SetMetadata,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './user.service';
import { Users } from './users.schema';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import { RolesGuard } from 'src/auth/roles.guard';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
@SetMetadata('roles', ['user'])
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Put(':id')
  async updateUser(
    @Param('id') id: string,
    @Body() updateData: Partial<Users>,
  ) {
    return this.usersService.update(id, updateData);
  }
}
