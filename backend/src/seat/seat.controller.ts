import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Put,
  UseGuards,
  SetMetadata,
} from '@nestjs/common';
import { SeatService } from './seat.service';
// import { CreateSeatDto } from './dto/create-seat.dto';
import { UpdateSeatDto } from './dto/update-seat.dto';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import { RolesGuard } from 'src/auth/roles.guard';

@Controller('seats')
@UseGuards(JwtAuthGuard, RolesGuard)
@SetMetadata('roles', ['user'])
export class SeatController {
  constructor(private readonly seatService: SeatService) {}

  // @SetMetadata('roles', ['admin'])
  // @Post()
  // createSeat(@Body() createSeatDto: CreateSeatDto) {
  //   return this.seatService.create(createSeatDto);
  // }
  @Get()
  getAll() {
    return this.seatService.findAll();
  }
  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.seatService.findOne(id);
  }
  @Get('trip/:tripId')
  getByTripId(@Param('tripId') tripId: string) {
    return this.seatService.findByTripId(tripId);
  }
  @Get('available/:tripId')
  async getAvailableSeats(@Param('tripId') tripId: string) {
    const availableSeats =
      await this.seatService.findAvailableSeatsByTrip(tripId);
    return availableSeats;
  }
  @Put(':id')
  updateSeat(@Param('id') id: string, @Body() updateSeatDto: UpdateSeatDto) {
    return this.seatService.update(id, updateSeatDto);
  }
}
