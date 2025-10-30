// src/payment/schemas/payment.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Transform } from 'class-transformer';
import { Document, Types } from 'mongoose';

export type PaymentDocument = Payment & Document;

@Schema()
export class Payment {
  @Prop({ type: Types.ObjectId, ref: 'Ticket', required: true })
  ticket_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  user_id: Types.ObjectId;

  @Transform(({ value }) => Number(value))
  @Prop({ required: true })
  amount: number;

  @Prop({ enum: ['paypal', 'cash'], required: true })
  payment_method: string;

  @Prop({
    enum: ['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED'],
  })
  payment_status: string;

  @Prop()
  payment_date: Date;

  @Prop()
  order_id?: string;
  @Prop()
  capture_id?: string;
}

export const PaymentSchema = SchemaFactory.createForClass(Payment);
