import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Ticket, TicketDocument } from './ticket.schema';
import { Model, Types } from 'mongoose';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { UpdateTicketDto } from './dto/update-ticket.dto';
import { Seat, SeatDocument, SeatStatus } from 'src/seat/seat.schema';

@Injectable()
export class TicketService {
  constructor(
    @InjectModel(Ticket.name) private ticketModel: Model<TicketDocument>,
    @InjectModel(Seat.name) private seatModel: Model<SeatDocument>,
  ) {}

  async create(dto: CreateTicketDto, userId: string): Promise<Ticket> {
    const seat = await this.seatModel.findById(dto.seat_id);
    if (!seat) {
      throw new NotFoundException('Không tìm thấy ghế');
    }

    if (seat.status_seat === SeatStatus.BOOKED) {
      throw new BadRequestException(' Ghế đã được đặt');
    }

    await this.seatModel.findByIdAndUpdate(dto.seat_id, {
      status_seat: SeatStatus.BOOKED,
    });
    const ticket = new this.ticketModel({
      ...dto,
      user_id: userId,
    });
    await ticket.save();

    const populatedTicket = await this.ticketModel
      .findById(ticket._id)
      .populate('user_id', 'full_name phone_number')
      .populate('trip_id', 'departure_location arrival_location price')
      .populate('seat_id', 'seat_number')
      .exec();

    if (!populatedTicket) {
      throw new NotFoundException('Không tìm thấy vé sau khi tạo');
    }

    return populatedTicket;
  }

  async findAll(): Promise<Ticket[]> {
    return this.ticketModel
      .find()
      .populate('user_id', 'full_name phone_number')
      .populate('trip_id', 'departure_location arrival_location price')
      .populate('seat_id', 'seat_number')
      .exec();
  }

  async findOne(id: string): Promise<Ticket> {
    const ticket = await this.ticketModel
      .findById(id)
      .populate('user_id', 'full_name phone_number')
      .populate('trip_id', 'departure_location arrival_location price')
      .populate('seat_id', 'seat_number')
      .exec();
    if (!ticket) throw new NotFoundException('Ticket not found');
    return ticket;
  }

  // async update(id: string, updateDto: UpdateTicketDto): Promise<Ticket> {
  //   const ticket = await this.ticketModel.findById(id);
  //   if (!ticket) throw new NotFoundException('Không tìm thấy vé');

  //   // Nếu hủy vé => cập nhật ghế thành trống
  //   if (updateDto.ticket_status === 'CANCELLED') {
  //     await this.seatModel.findByIdAndUpdate(ticket.seat_id, {
  //       is_available: true,
  //     });
  //   }

  //   ticket.ticket_status = updateDto.ticket_status ?? ticket.ticket_status;
  //   await ticket.save();

  //   const updatedTicket = await this.ticketModel
  //     .findById(ticket._id)
  //     .populate('user_id', 'full_name phone_number')
  //     .populate('trip_id', 'departure_location arrival_location price')
  //     .populate('seat_id', 'seat_number')
  //     .exec();
  //   if (!updatedTicket) {
  //     throw new NotFoundException('Không tìm thấy vé sau khi cập nhật');
  //   }
  //   return updatedTicket;
  // }

  async update(id: string, updateDto: UpdateTicketDto): Promise<Ticket> {
    const ticket = await this.ticketModel.findById(id);
    if (!ticket) throw new NotFoundException('Không tìm thấy vé');

    // Kiểm tra nếu có seat_id mới trong updateDto
    if (
      updateDto.seat_id &&
      updateDto.seat_id.toString() !== ticket.seat_id?.toString()
    ) {
      // Kiểm tra ghế mới có tồn tại không
      const newSeat = await this.seatModel.findById(updateDto.seat_id);
      if (!newSeat) {
        throw new NotFoundException('Không tìm thấy ghế mới');
      }

      // Kiểm tra trạng thái ghế mới
      if (newSeat.status_seat === SeatStatus.BOOKED) {
        throw new BadRequestException('Ghế mới đã được đặt');
      }

      // Cập nhật trạng thái ghế cũ thành AVAILABLE
      await this.seatModel.findByIdAndUpdate(ticket.seat_id, {
        status_seat: SeatStatus.AVAILABLE,
        updated_at: new Date(),
      });

      // Cập nhật trạng thái ghế mới thành BOOKED
      await this.seatModel.findByIdAndUpdate(updateDto.seat_id, {
        status_seat: SeatStatus.BOOKED,
        updated_at: new Date(),
      });

      // Gán seat_id mới cho vé
      ticket.seat_id = new Types.ObjectId(updateDto.seat_id);
    }

    // Nếu hủy vé, cập nhật ghế thành AVAILABLE
    if (updateDto.ticket_status === 'CANCELLED') {
      await this.seatModel.findByIdAndUpdate(ticket.seat_id, {
        status_seat: SeatStatus.AVAILABLE,
        updated_at: new Date(),
      });
    }

    // Cập nhật ticket_status nếu có
    ticket.ticket_status = updateDto.ticket_status ?? ticket.ticket_status;
    await ticket.save();

    // Populate dữ liệu trả về
    const updatedTicket = await this.ticketModel
      .findById(ticket._id)
      .populate('user_id', 'full_name phone_number')
      .populate('trip_id', 'departure_location arrival_location price')
      .populate('seat_id', 'seat_number')
      .exec();
    if (!updatedTicket) {
      throw new NotFoundException('Không tìm thấy vé sau khi cập nhật');
    }
    return updatedTicket;
  }

  async remove(id: string): Promise<void> {
    const result = await this.ticketModel.findByIdAndDelete(id).exec();
    if (result) {
      await this.seatModel.findByIdAndUpdate(result.seat_id, {
        is_available: true,
      });
      if (!result) throw new NotFoundException('Không tìm thấy vé để xoá');
    }
  }
  async findTicketByUserId(userId: string): Promise<Ticket[]> {
    return this.ticketModel
      .find({ user_id: userId })
      .populate('user_id', 'full_name phone_number')
      .populate('trip_id', 'departure_location arrival_location price')
      .populate('seat_id', 'seat_number')
      .exec();
  }
}
