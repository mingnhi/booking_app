import { IsMongoId, IsEnum, IsOptional } from 'class-validator';

export class CreateTicketDto {
  @IsMongoId()
  user_id: string;
  @IsMongoId()
  trip_id: string;

  @IsMongoId()
  seat_id: string;

  @IsOptional()
  @IsEnum(['booked', 'cancelled', 'completed'])
  ticket_status?: 'BOOKED' | 'CANCELLED' | 'COMPLETED';
}
