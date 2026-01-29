// Nigerian UI Components - Complete Export
// Includes bank selection, state selection, phone input, and currency display

// Bank Components
export { BankSelect, BankDisplay, nigerianBanks, getBankByCode } from './BankSelect';
export { NigerianBankSelect, NIGERIAN_BANKS, type NigerianBank } from './NigerianBankSelect';

// State Components
export { StateSelect, RegionSelect, nigerianStates, getStateByCode } from './StateSelect';
export { NigerianStateSelect, NIGERIAN_STATES, type NigerianState, type GeopoliticalZone } from './NigerianStateSelect';

// Currency & Naira Components
export { NairaDisplay, NairaInput, NairaRange, formatNaira, parseNaira } from './NairaFormat';
export {
    CurrencyDisplay,
    ExchangeRateDisplay,
    RemittanceConversion,
    CURRENCIES,
    type CurrencyCode
} from './CurrencyDisplay';

// Phone Components
export { NigerianPhoneInput, PhoneDisplay, formatNigerianPhone, validateNigerianPhone, detectMNO, nigerianMNOs } from './PhoneInput';
export {
    NigerianPhoneInput as PhoneInputEnhanced,
    NIGERIAN_CARRIERS,
    type NigerianCarrier,
    detectCarrier,
    toInternationalFormat
} from './NigerianPhoneInput';
