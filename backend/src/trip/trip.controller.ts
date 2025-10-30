import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { TripService } from './trip.service';
// import { CreateTripDto } from './dto/create-trip.dto';
// import { UpdateTripDto } from './dto/update-trip.dto';;
import { Trip } from './trip.schema';

@Controller('trip')
export class TripController {
  constructor(private readonly tripService: TripService) {}

  @Get()
  getAll() {
    return this.tripService.findAll();
  }

  @Post('search')
  async searchTrips(
    @Body('departure_location') departure_location?: string,
    @Body('arrival_location') arrival_location?: string,
    @Body('departure_time') departure_time?: string,
  ): Promise<Trip[]> {
    const departureTime = departure_time ? new Date(departure_time) : undefined;
    return this.tripService.searchTrips(
      departure_location,
      arrival_location,
      departureTime,
    );
  }

  getOne(@Param('id') id: string) {
    return this.tripService.findOne(id);
  }
}
