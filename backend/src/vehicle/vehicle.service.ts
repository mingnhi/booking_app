import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Vehicle, VehicleDocument } from './vehicle.shema';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { Model } from 'mongoose';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';

@Injectable()
export class VehicleService {
  constructor(
    @InjectModel(Vehicle.name) private vehicleModel: Model<VehicleDocument>,
  ) {}
  async create(dto: CreateVehicleDto): Promise<Vehicle> {
    return this.vehicleModel.create(dto);
  }

  async findAll(): Promise<Vehicle[]> {
    return this.vehicleModel.find().exec();
  }

  async findOne(id: string): Promise<Vehicle> {
    const vehicle = await this.vehicleModel.findById(id).exec();
    if (!vehicle) {
      throw new NotFoundException('Vehicle not found');
    }
    return vehicle;
  }

  async update(
    id: string,
    updateVehicleDto: UpdateVehicleDto,
  ): Promise<Vehicle> {
    const update_vehicel = await this.vehicleModel.findByIdAndUpdate(
      id,
      updateVehicleDto,
      { new: true },
    );
    if (!update_vehicel) {
      throw new NotFoundException('Vehicle not found to update');
    }
    return update_vehicel;
  }

  async remove(id: string): Promise<void> {
    const delete_vehicle = await this.vehicleModel.findByIdAndDelete(id);
    if (!delete_vehicle) {
      throw new NotFoundException('Vehicle not found to delete');
    }
  }
}
