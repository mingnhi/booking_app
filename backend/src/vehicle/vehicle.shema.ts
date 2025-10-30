import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type VehicleDocument = Vehicle & Document;

@Schema()
export class Vehicle {
  @Prop({ required: true, unique: true })
  license_plate: string;

  @Prop()
  description: string;
}

export const VehicleSchema = SchemaFactory.createForClass(Vehicle);
