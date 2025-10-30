import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TicketDocument = Ticket & Document;
@Schema({ timestamps: { createdAt: 'booked_at' } })
export class Ticket {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  user_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Trip', required: true })
  trip_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Seat', required: true })
  seat_id: Types.ObjectId;

  @Prop({
    type: String,
    enum: ['BOOKED', 'CANCELLED', 'COMPLETED'],
    default: 'BOOKED',
  })
  ticket_status: 'BOOKED' | 'CANCELLED' | 'COMPLETED';
}
export const TicketSchema = SchemaFactory.createForClass(Ticket);
