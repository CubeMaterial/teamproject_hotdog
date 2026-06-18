from enum import IntEnum


class RefundState(IntEnum):
    REQUESTED = 0
    ON_HOLD = 1
    CONFIRMED = 2
    CANCELED = 3


REFUND_STATE_LABELS = {
    RefundState.REQUESTED: "환불신청",
    RefundState.ON_HOLD: "환불보류",
    RefundState.CONFIRMED: "환불완료",
    RefundState.CANCELED: "환불취소",
}
