// Nigerian UI Components - Anti-Call Masking
// Phone and State utilities for CLI validation

// Currency Components
export { NairaDisplay, NairaText, formatNaira } from './NairaDisplay';

// State Components (for location reference)
export { StateSelect, RegionSelect, nigerianStates, getStateByCode } from './StateSelect';
export { NigerianStateSelect, NIGERIAN_STATES, type NigerianState, type GeopoliticalZone } from './NigerianStateSelect';

// Phone Components (for CLI/MNO detection)
export { NigerianPhoneInput, PhoneDisplay, formatNigerianPhone, validateNigerianPhone, detectMNO, nigerianMNOs } from './PhoneInput';
export {
    NigerianPhoneInput as PhoneInputEnhanced,
    NIGERIAN_CARRIERS,
    type NigerianCarrier,
    detectCarrier,
    toInternationalFormat
} from './NigerianPhoneInput';

