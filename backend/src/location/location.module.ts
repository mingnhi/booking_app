import { Module } from '@nestjs/common';
import { LocationService } from './location.service';
import { LocationController } from './location.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { Location, LocationSchema } from './location.schema';
import { UsersModule } from 'src/users/users.module';

@Module({
  imports: [
    UsersModule,
    MongooseModule.forFeature([
      { name: Location.name, schema: LocationSchema },
    ]),
  ],
  controllers: [LocationController],
  providers: [LocationService],
  exports: [LocationService, MongooseModule],
})
export class LocationModule {}
