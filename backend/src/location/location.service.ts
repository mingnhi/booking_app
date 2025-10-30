import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Location, LocationDocument } from './location.schema';
import { CreateLocationDto } from './dto/create-location.dto';
import { UpdateLocationDto } from './dto/update-location.dto';

@Injectable()
export class LocationService {
  constructor(
    @InjectModel(Location.name)
    private readonly model: Model<LocationDocument>,
  ) {}

  create(dto: CreateLocationDto) {
    return this.model.create(dto);
  }
  async findAll(): Promise<Location[]> {
    return this.model.find().exec();
  }
  async findOne(id: string) {
    const location = await this.model.findById(id).exec();
    if (!location) {
      throw new NotFoundException('location not found');
    }
    return location;
  }
  async update(id: string, dto: UpdateLocationDto): Promise<Location> {
    const location = await this.model.findByIdAndUpdate(id, dto, { new: true });
    if (!location) {
      throw new NotFoundException('Location not found');
    }
    return location;
  }

  async remove(id: string) {
    const result = await this.model.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException('Location not found');
    }
    return result;
  }
}
