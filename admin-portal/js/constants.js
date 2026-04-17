// admin-portal/js/constants.js

export const ORDER_STATUS = {
  PENDING: 'Pending',
  PREPARING: 'Preparing',
  READY_FOR_PICKUP: 'Ready for Pickup',
  COMPLETED: 'Completed',
  CANCELLED: 'Cancelled'
};

export const ORDER_STATUS_LIST = [
  ORDER_STATUS.PENDING,
  ORDER_STATUS.PREPARING,
  ORDER_STATUS.READY_FOR_PICKUP,
  ORDER_STATUS.COMPLETED,
  ORDER_STATUS.CANCELLED
];

export const RIDER_STATUS = {
  ONBOARDING: 'onboarding',
  PENDING_APPROVAL: 'pending_approval',
  ACTIVE: 'active',
  SUSPENDED: 'suspended'
};

export const VENUE_TYPE = {
  CANTEEN: 'canteen',
  RESTAURANT: 'restaurant'
};

export const COLLECTIONS = {
  ORDERS: 'Orders',
  RIDERS: 'Riders',
  CANTEENS: 'Canteens',
  USERS: 'Users',
  OWNERS: 'Owners'
};
