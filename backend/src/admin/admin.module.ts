import { Module } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { UsersModule } from 'src/users/users.module';
import { TripModule } from 'src/trip/trip.module';
import { SeatModule } from 'src/seat/seat.module';
import { TicketModule } from 'src/ticket/ticket.module';
import { LocationModule } from 'src/location/location.module';
// import { Vehicle } from 'src/vehicle/vehicle.shema';
import { VehicleModule } from 'src/vehicle/vehicle.module';
import { PaymentModule } from 'src/payment/payment.module';

@Module({
  imports: [
    UsersModule,
    TripModule,
    SeatModule,
    TicketModule,
    UsersModule,
    LocationModule,
    VehicleModule,
    PaymentModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
