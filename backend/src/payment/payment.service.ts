import {
  ConflictException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Payment, PaymentDocument } from './payment.shema';
import mongoose, { Model } from 'mongoose';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { Ticket, TicketDocument } from 'src/ticket/ticket.schema';
import { Seat, SeatDocument, SeatStatus } from 'src/seat/seat.schema';

@Injectable()
export class PaymentService {
  constructor(
    @InjectModel(Payment.name) private paymentModel: Model<PaymentDocument>,
    @InjectModel(Ticket.name) private ticketModel: Model<TicketDocument>,
    @InjectModel(Seat.name) private seatModel: Model<SeatDocument>,
  ) {}

  async create(
    userId: string,
    createPaymentDto: CreatePaymentDto,
  ): Promise<{ message: string; ticketStatus: string }> {
    try {
      const {
        ticket_id,
        amount,
        payment_method,
        payment_status,
        order_id,
        capture_id,
      } = createPaymentDto;

      const ticket = await this.ticketModel.findById(ticket_id);
      if (!ticket) {
        throw new NotFoundException('Ticket not found');
      } else if (ticket.ticket_status === 'COMPLETED') {
        throw new ConflictException('Ticket already completed');
      }

      if (ticket.user_id.toString() !== userId) throw new ForbiddenException();

      if (payment_method === 'paypal' && !order_id) {
        throw new Error('Thiếu order ID từ PayPal');
      }

      ticket.ticket_status =
        payment_status === 'COMPLETED' ? 'COMPLETED' : 'BOOKED';
      await ticket.save();

      if (payment_status === 'COMPLETED') {
        await this.seatModel.findByIdAndUpdate(ticket.seat_id, {
          status_seat: SeatStatus.BOOKED,
        });
      }

      const payment = new this.paymentModel({
        user_id: userId,
        ticket_id: new mongoose.Types.ObjectId(ticket_id),
        amount,
        payment_method,
        payment_status,
        payment_date: new Date(),
        order_id,
        capture_id,
      });

      await payment.save();

      return {
        message: 'Thanh toán đã được ghi nhận',
        ticketStatus: ticket.ticket_status,
      };
    } catch (error) {
      console.error('Lỗi khi tạo thanh toán:', error);
      throw new InternalServerErrorException(
        ' Đã xảy ra lỗi khi xử lý thanh toán ',
      );
    }
  }

  async findByUserId(userId: string): Promise<Payment[]> {
    return this.paymentModel
      .find({ user_id: userId })
      .populate('user_id')
      .populate({
        path: 'ticket_id',
        populate: [
          {
            path: 'trip_id',
            select: 'departure_location arrival_location price',
          },
          {
            path: 'seat_id',
            select: 'seat_number status_seat',
          },
        ],
      })
      .exec();
  }

  async findAll(): Promise<Payment[]> {
    return this.paymentModel
      .find()
      .populate('user_id', 'full_name')
      .populate({
        path: 'ticket_id',
        populate: [
          {
            path: 'trip_id',
            select: 'departure_location arrival_location price',
          },
          { path: 'seat_id', select: 'seat_number' },
        ],
      })
      .exec();
  }

  async findbyTicketId(ticketId: string): Promise<Payment> {
    const payment = await this.paymentModel
      .findOne({ ticket_id: ticketId })
      .populate('user_id', 'full_name')
      .exec();
    if (!payment) {
      throw new NotFoundException('Payment with id ${ticketId} not found');
    }
    return payment;
  }

  async update(id: string, status: string): Promise<Payment> {
    const payment = await this.paymentModel.findByIdAndUpdate(id);
    if (!payment) {
      throw new NotFoundException('Payment with not found');
    }
    payment.payment_status = status;
    payment.payment_date = new Date();
    return payment.save();
  }

  async refundPayment(
    paymentId: string,
    userId: string,
  ): Promise<{ message: string }> {
    const session = await this.paymentModel.startSession();
    session.startTransaction();

    try {
      const payment = await this.paymentModel
        .findById(paymentId)
        .session(session);
      if (!payment) {
        throw new NotFoundException('Payment not found');
      }

      if (payment.user_id.toString() !== userId) {
        throw new ForbiddenException('Bạn không có quyền hoàn tiền giao dịch');
      }

      if (payment.payment_status !== 'COMPLETED') {
        throw new ConflictException(
          'Chỉ có thể hoàn tiền khi giao dịch hoàn tất',
        );
      }
      payment.payment_status = 'REFUNDED';
      payment.payment_date = new Date();
      await payment.save({ session });

      const ticket = await this.ticketModel
        .findById(payment.ticket_id)
        .session(session);
      if (ticket) {
        ticket.ticket_status = 'CANCELLED';
        await ticket.save({ session });

        if (ticket.seat_id) {
          await this.seatModel.findByIdAndUpdate(
            ticket.seat_id,
            { status_seat: SeatStatus.AVAILABLE },
            { session },
          );
        }
      }
      await session.commitTransaction();
      return { message: 'Hoàn tiền thành công' };
    } catch (error) {
      await session.abortTransaction();
      console.error('Lỗi khi hoàn tiền: ', error);
      throw new InternalServerErrorException('lỗi khi xử lý hoàn tiền');
    } finally {
      session.endSession();
    }
  }

  async updateOrderId(orderId: string): Promise<{ message: string }> {
    const payment = await this.paymentModel.findOne({ order_id: null });

    if (!payment) {
      throw new NotFoundException('Không tìm thấy thanh toán chưa có Order ID');
    }

    payment.order_id = orderId;
    await payment.save();

    return { message: 'Đã cập nhật Order ID thành công' };
  }
}
