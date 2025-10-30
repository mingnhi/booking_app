import { IsNumber, IsMongoId, IsNotEmpty, IsEnum } from 'class-validator';
import { Types } from 'mongoose';
import { SeatStatus } from '../seat.schema';

export class CreateSeatDto {
  @IsMongoId()
  trip_id: Types.ObjectId;

  @IsNumber()
  @IsNotEmpty()
  seat_number: number;

  @IsEnum(SeatStatus)
  status_seat: SeatStatus;
}
