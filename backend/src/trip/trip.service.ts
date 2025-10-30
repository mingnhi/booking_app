import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Trip, TripDocument } from './trip.schema';
import { Model, Types } from 'mongoose';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';
import { Seat, SeatDocument, SeatStatus } from 'src/seat/seat.schema';
import { Location, LocationDocument } from 'src/location/location.schema';
import { SeatService } from 'src/seat/seat.service';
// import { PopulatedTrip } from './dto/populated';

@Injectable()
export class TripService {
  constructor(
    @InjectModel(Trip.name) private tripModel: Model<TripDocument>,
    @InjectModel(Seat.name) private seatModel: Model<SeatDocument>,
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    private readonly seatService: SeatService,
  ) {}

  async create(createTripDto: CreateTripDto): Promise<Trip> {
    const newTrip = await this.tripModel.create(createTripDto);

    const seats: Partial<SeatDocument>[] = [];
    for (let i = 1; i <= createTripDto.total_seats; i++) {
      seats.push({
        trip_id: newTrip._id,
        seat_number: i,
        status_seat: SeatStatus.AVAILABLE,
      });
    }
    await this.seatModel.insertMany(seats);
    const populatedTrip = await this.tripModel
      .findById(newTrip._id)
      .populate('departure_location', 'name')
      .populate('arrival_location', 'name')
      .populate('vehicle_id')
      .exec();
    if (!populatedTrip) {
      throw new NotFoundException('Trip not found');
    }

    return populatedTrip;
  }

  async findAll(): Promise<Trip[]> {
    return this.tripModel.find().exec();
  }

  async findOne(id: string): Promise<Trip> {
    const trip = await this.tripModel.findById(id).exec();
    if (!trip) {
      throw new NotFoundException('Trip with id ${id} not found');
    }
    return trip;
  }

  async update(id: string, updateTripDto: UpdateTripDto): Promise<Trip> {
    const updated = await this.tripModel
      .findByIdAndUpdate(id, updateTripDto, { new: true })
      .exec();
    if (!updated) {
      throw new NotFoundException('Trip with id ${id} not found');
    }
    return updated;
  }

  async remove(id: string): Promise<Trip> {
    const deleted = await this.tripModel.findByIdAndDelete(id).exec();
    if (!deleted) {
      throw new NotFoundException('Trip with ID ${id} not found');
    }
    return deleted;
  }

  // async remove(id: string): Promise<void> {
  //   const trip = await this.tripModel.findById(id);
  //   if (!trip) {
  //     throw new NotFoundException('Trip with ID ${id} not found');
  //   }
  //   await this.seatService.removeByTripId(id);
  //   await trip.deleteOne();
  // }
  async searchTrips(
    departure_location?: string,
    arrival_location?: string,
    departure_time?: Date,
  ): Promise<Trip[]> {
    const query: any = {};

    if (departure_location && typeof departure_location === 'string') {
      query.departure_location = {
        $regex: departure_location,
        $options: 'i',
      };
    }

    if (arrival_location && typeof arrival_location === 'string') {
      query.arrival_location = {
        $regex: arrival_location,
        $options: 'i',
      };
    }

    if (departure_time) {
      const start = new Date(departure_time);
      start.setHours(0, 0, 0, 0);
      const end = new Date(departure_time);
      end.setHours(23, 59, 59, 999);
      query.departure_time = { $gte: start, $lte: end };
    }

    return this.tripModel.find(query).exec();
  }
}
