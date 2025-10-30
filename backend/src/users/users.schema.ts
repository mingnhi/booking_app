import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
export type UsersDocument = Users & Document;
@Schema({ timestamps: { createdAt: 'create_at' } })
export class Users {
  @Prop({ required: true })
  full_name: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password: string;

  @Prop()
  phone_number: string;
  @Prop()
  refresh_token?: string;
  @Prop({ enum: ['user', 'admin'], default: 'user' })
  role: string;
}
export const UsersSchema = SchemaFactory.createForClass(Users);
