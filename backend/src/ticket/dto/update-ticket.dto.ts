import { IsEnum, IsOptional } from 'class-validator';

export class UpdateTicketDto {
  @IsOptional()
  @IsEnum(['BOOKED', 'CANCELLED', 'COMPLETED'])
  ticket_status?: 'BOOKED' | 'CANCELLED' | 'COMPLETED';

  @IsOptional()
  seat_id?: string;

  @IsOptional()
  trip_id?: string;
}
