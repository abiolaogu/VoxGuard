//! Anti-Call Masking Detection Service - Domain Layer
//!
//! This module contains the core domain logic for fraud detection following DDD principles.
//! All business rules are encapsulated in aggregates and value objects.

pub mod domain;
pub mod application;
pub mod ports;
pub mod adapters;
pub mod config;
pub mod metrics;

pub use domain::*;
pub use application::*;
pub use ports::*;
