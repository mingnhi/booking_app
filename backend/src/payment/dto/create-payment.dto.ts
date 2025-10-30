// src/payment/dto/create-payment.dto.ts
import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';
import { Types } from 'mongoose';
import { Transform } from 'class-transformer';
export class CreatePaymentDto {
  @Transform(({ value }) => new Types.ObjectId(value))
  @IsMongoId()
  @IsString()
  @IsNotEmpty()
  ticket_id: string;

  @IsNumber()
  amount: number;

  @IsEnum(['paypal', 'cash'])
  payment_method: 'paypal' | 'cash';

  @IsEnum(['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED'])
  @IsOptional()
  payment_status?: 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';

  @IsOptional()
  payment_date?: Date;

  @IsOptional()
  @IsString()
  order_id?: string;

  @IsOptional()
  @IsString()
  capture_id?: string;
}
