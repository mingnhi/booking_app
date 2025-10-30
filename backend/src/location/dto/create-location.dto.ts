import { IsNotEmpty, IsString } from 'class-validator';

export class CreateLocationDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  description?: string;

  @IsString()
  @IsNotEmpty()
  contact_phone: string;
}
