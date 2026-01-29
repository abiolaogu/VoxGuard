package com.billyrinks.antimasking.di

import com.billyrinks.antimasking.data.repository.AntiMaskingRepositoryImpl
import com.billyrinks.antimasking.data.repository.MarketplaceRepositoryImpl
import com.billyrinks.antimasking.data.repository.RemittanceRepositoryImpl
import com.billyrinks.antimasking.domain.repository.AntiMaskingRepository
import com.billyrinks.antimasking.domain.repository.MarketplaceRepository
import com.billyrinks.antimasking.domain.repository.RemittanceRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Repository module that binds interfaces to implementations
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAntiMaskingRepository(
        impl: AntiMaskingRepositoryImpl
    ): AntiMaskingRepository

    @Binds
    @Singleton
    abstract fun bindRemittanceRepository(
        impl: RemittanceRepositoryImpl
    ): RemittanceRepository

    @Binds
    @Singleton
    abstract fun bindMarketplaceRepository(
        impl: MarketplaceRepositoryImpl
    ): MarketplaceRepository
}
