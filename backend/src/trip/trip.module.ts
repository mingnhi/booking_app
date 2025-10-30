import { Module } from '@nestjs/common';
import { TripService } from './trip.service';
import { TripController } from './trip.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { Trip, TripSchema } from './trip.schema';
import { UsersModule } from 'src/users/users.module';
import { SeatModule } from 'src/seat/seat.module';
import { LocationModule } from 'src/location/location.module';

@Module({
  imports: [
    UsersModule,
    SeatModule,
    LocationModule,
    MongooseModule.forFeature([{ name: Trip.name, schema: TripSchema }]),
  ],
  controllers: [TripController],
  providers: [TripService],
  exports: [TripService],
})
export class TripModule {}
