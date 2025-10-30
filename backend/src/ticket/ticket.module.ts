import { Module } from '@nestjs/common';
import { TicketService } from './ticket.service';
import { TicketController } from './ticket.controller';
import { UsersModule } from 'src/users/users.module';
import { MongooseModule } from '@nestjs/mongoose';
import { Ticket, TicketSchema } from './ticket.schema';
import { SeatModule } from 'src/seat/seat.module';
import { TripModule } from 'src/trip/trip.module';
import { UsersSchema } from 'src/users/users.schema';

@Module({
  imports: [
    UsersModule,
    SeatModule,
    TripModule,
    MongooseModule.forFeature([
      { name: Ticket.name, schema: TicketSchema },
      { name: 'User', schema: UsersSchema },
    ]),
  ],
  controllers: [TicketController],
  providers: [TicketService],
  exports: [TicketService, MongooseModule],
})
export class TicketModule {}
