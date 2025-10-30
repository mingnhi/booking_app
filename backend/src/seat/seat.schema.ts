import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SeatDocument = Seat & Document;

export enum SeatStatus {
  AVAILABLE = 'AVAILABLE',
  BOOKED = 'BOOKED',
  UNAVAILABLE = 'UNAVAILABLE',
}
@Schema({ timestamps: true })
export class Seat {
  @Prop({ type: Types.ObjectId, ref: 'Trip', required: true })
  trip_id: Types.ObjectId;

  @Prop({ required: true })
  seat_number: number;

  @Prop({
    type: String,
    enum: SeatStatus,
    default: SeatStatus.AVAILABLE,
  })
  status_seat: SeatStatus;
}
export const SeatSchema = SchemaFactory.createForClass(Seat);
