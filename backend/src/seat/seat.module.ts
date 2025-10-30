import { Module } from '@nestjs/common';
import { SeatService } from './seat.service';
import { SeatController } from './seat.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { Seat, SeatSchema } from './seat.schema';
import { UsersModule } from 'src/users/users.module';

@Module({
  imports: [
    UsersModule,
    MongooseModule.forFeature([{ name: Seat.name, schema: SeatSchema }]),
  ],
  controllers: [SeatController],
  providers: [SeatService],
  exports: [SeatService, MongooseModule],
})
export class SeatModule {}
