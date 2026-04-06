export enum EntityStatusEnum {
  Inactive = 0,
  Active = 1,
  Pending = 2,
  Rejected = 3,
}

export enum RoleEnum {
  SystemAdmin = 0,
  BrandManager = 1,
  StoreManager = 2,
}

export interface BasePaginationFilter {
  page?: number;
  pageSize?: number;
  search?: string;
  sortBy?: string;
  isAscending?: boolean;
  status?: EntityStatusEnum;
}

export type BaseResponse = {
  id: string;
  createdAt: string;
  updatedAt: string | null;
  createdBy: string | null;
  updatedBy: string | null;
  status: EntityStatusEnum;
};

export interface Result<T = any> {
  isSuccess: boolean;
  message: string;
  data?: T;
  errors?: Array<{ field: string; message: string }> | null;
  errorCode?: string | null;
}

export type PaginationResult<T> = {
  currentPage: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasPrevious: boolean;
  hasNext: boolean;
  items: T[];
};
