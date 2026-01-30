//! Domain Layer - Core business logic and entities
//!
//! Contains aggregates, entities, value objects, and domain events
//! following Domain-Driven Design principles.

pub mod aggregates;
pub mod value_objects;
pub mod events;
pub mod errors;

pub use aggregates::*;
pub use value_objects::*;
pub use events::*;
pub use errors::*;
