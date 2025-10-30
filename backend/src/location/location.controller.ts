import {
  // Body,
  Controller,
  Get,
  // Delete,
  // Get,
  // Param,
  // Post,
  // Put,
} from '@nestjs/common';
import { LocationService } from './location.service';

@Controller('location')
export class LocationController {
  constructor(private readonly locationService: LocationService) {}

  // @Post()
  // createLocation(@Body() dto: CreateLocationDto) {
  //   return this.locationService.create(dto);
  // }

  @Get()
  findAll() {
    return this.locationService.findAll();
  }

  // @Get(':id')
  // findOne(@Param('id') id: string) {
  //   return this.locationService.findOne(id);
  // }

  // @Put(':id')
  // updateLocation(@Param('id') id: string, @Body() dto: UpdateLocationDto) {
  //   return this.locationService.update(id, dto);
  // }

  // @Delete(':id')
  // delete(@Param('id') id: string) {
  //   return this.locationService.remove(id);
  // }
}
