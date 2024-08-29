export const STATUSES = ['RUNNING', 'SUCCESS', 'FAILED', 'CANCELED', 'BLOCKED'];
export const FINISHED_STATUSES = ['SUCCESS', 'FAILED', 'CANCELED'];
export const UPCOMING_STATUSES = ['RUNNING', 'BLOCKED'];

export const isFinished = ({ status }) => FINISHED_STATUSES.includes(status);
