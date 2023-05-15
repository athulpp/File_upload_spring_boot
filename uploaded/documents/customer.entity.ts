import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class ResellerCustomer {
    @Column({ unique: true })
  id: number;

  @PrimaryGeneratedColumn()
  @Column({ name: 'reseller_customer_id' })
  resellerCustomerId: number;

  @Column({ name: 'reseller_customer_ref_id', unique: true })
  resellerCustomerRefId: string;

  @Column()
  ref_id: string;

  @Column({ name: 'reseller_id' })
  resellerId: number;

  @Column({ name: 'reseller_store_id' })
  resellerStoreId: number;

  @Column()
  name: string;

  @Column()
  mobile: string;

  @Column()
  phone: string;

  @Column()
  email: string;

  @Column({ name: 'address1' })
  address1: string;

  @Column({ name: 'address2' })
  address2: string;

  @Column()
  state: string;

  @Column({ name: 'state_code' })
  stateCode: string;

  @Column()
  gstin: string;

  @Column()
  type: string;

  @Column({ name: 'created_on' })
  createdOn: Date;

  @Column({ name: 'created_by' })
  createdBy: number;

  @Column({ name: 'modified_on' })
  modifiedOn: Date;

  @Column({ name: 'modified_by' })
  modifiedBy: number;

  @Column({ name: 'customer_id' })
  customerId: number;

  @Column({ name: 'is_imported' })
  isImported: boolean;

  @Column({ name: 'sync_status' })
  syncStatus: number;
}
