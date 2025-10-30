import {
  IsNotEmpty,
  IsMongoId,
  IsDateString,
  IsNumber,
  IsString,
} from 'class-validator';

export class CreateTripDto {
  @IsMongoId()
  @IsNotEmpty()
  vehicle_id: string;

  @IsMongoId()
  @IsNotEmpty()
  departure_location: string;

  @IsMongoId()
  @IsNotEmpty()
  arrival_location: string;

  @IsDateString()
  @IsNotEmpty()
  departure_time: Date;

  @IsDateString()
  @IsNotEmpty()
  arrival_time: Date;

  @IsNumber()
  @IsNotEmpty()
  price: number;

  @IsString()
  @IsNotEmpty()
  distance: number;

  @IsNumber()
  @IsNotEmpty()
  total_seats: number;
}
