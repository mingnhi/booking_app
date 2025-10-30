import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Seat, SeatDocument, SeatStatus } from './seat.schema';
import mongoose, { Model } from 'mongoose';
import { CreateSeatDto } from './dto/create-seat.dto';
import { UpdateSeatDto } from './dto/update-seat.dto';

@Injectable()
export class SeatService {
  constructor(@InjectModel(Seat.name) private seatModel: Model<SeatDocument>) {}
  async create(createSeatDto: CreateSeatDto): Promise<Seat> {
    return this.seatModel.create(createSeatDto);
  }

  async findAvailableSeatsByTrip(
    tripId: string,
  ): Promise<{ total: number; seats: Seat[] }> {
    const availableSeats = await this.seatModel.find({
      trip_id: new mongoose.Types.ObjectId(tripId),
      status_seat: SeatStatus.AVAILABLE,
    });

    return {
      total: availableSeats.length,
      seats: availableSeats,
    };
  }

  async findAll(): Promise<Seat[]> {
    return this.seatModel.find().exec();
  }

  async findOne(id: string): Promise<Seat> {
    const seat = await this.seatModel.findById(id).exec();
    if (!seat) {
      throw new NotFoundException('Seat not found');
    }
    return seat;
  }
  async update(id: string, updateSeatDto: UpdateSeatDto): Promise<Seat> {
    const updated = await this.seatModel
      .findByIdAndUpdate(id, updateSeatDto, { new: true })
      .exec();
    if (!updated) throw new NotFoundException('Seat not found');
    return updated;
  }
  async findByTripId(tripId: string): Promise<Seat[]> {
    return this.seatModel.find({ trip_id: tripId }).exec();
  }

  async remove(id: string): Promise<{ message: string }> {
    const deleted = await this.seatModel.findByIdAndDelete(id).exec();
    if (!deleted) {
      throw new NotFoundException('Seat not found');
    }
    return { message: 'Seat deleted successfully' };
  }

  // async remove(id: string): Promise<void> {
  //   const result = await this.seatModel.findByIdAndDelete(id).exec();
  //   if (!result) throw new NotFoundException('Seat not found');
  // }
  // async removeByTripId(tripId: string): Promise<void> {
  //   const result = await this.seatModel.deleteMany({ trip_id: tripId }).exec();
  //   if (result.deletedCount === 0) {
  //     throw new NotFoundException(`No seats found for trip_id ${tripId}`);
  //   }
  // }
}
