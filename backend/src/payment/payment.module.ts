import { Module } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { PaymentController } from './payment.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { Payment, PaymentSchema } from './payment.shema';
import { UsersModule } from 'src/users/users.module';
import { Ticket, TicketSchema } from 'src/ticket/ticket.schema';
import { Trip, TripSchema } from 'src/trip/trip.schema';
import { SeatModule } from 'src/seat/seat.module';

@Module({
  imports: [
    UsersModule,
    SeatModule,
    MongooseModule.forFeature([
      { name: Payment.name, schema: PaymentSchema },
      { name: Ticket.name, schema: TicketSchema },
      { name: Trip.name, schema: TripSchema },
    ]),
  ],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService],
})
export class PaymentModule {}
