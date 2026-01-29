import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Result, Button, Typography, Space, Card } from 'antd';
import { ReloadOutlined, HomeOutlined, BugOutlined } from '@ant-design/icons';

const { Text, Paragraph } = Typography;

interface ErrorBoundaryProps {
    children: ReactNode;
    fallback?: ReactNode;
    onError?: (error: Error, errorInfo: ErrorInfo) => void;
}

interface ErrorBoundaryState {
    hasError: boolean;
    error: Error | null;
    errorInfo: ErrorInfo | null;
}

/**
 * Error boundary with friendly error messages
 */
export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
    constructor(props: ErrorBoundaryProps) {
        super(props);
        this.state = {
            hasError: false,
            error: null,
            errorInfo: null,
        };
    }

    static getDerivedStateFromError(error: Error): Partial<ErrorBoundaryState> {
        return { hasError: true, error };
    }

    componentDidCatch(error: Error, errorInfo: ErrorInfo) {
        this.setState({ errorInfo });
        this.props.onError?.(error, errorInfo);

        // Log to error tracking service
        console.error('Error caught by boundary:', error, errorInfo);
    }

    handleReload = () => {
        window.location.reload();
    };

    handleGoHome = () => {
        window.location.href = '/';
    };

    render() {
        if (this.state.hasError) {
            if (this.props.fallback) {
                return this.props.fallback;
            }

            return (
                <div
                    style={{
                        minHeight: '100vh',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        padding: 24,
                        background: '#f5f5f5',
                    }}
                >
                    <Card
                        style={{
                            maxWidth: 500,
                            width: '100%',
                            borderRadius: 12,
                            boxShadow: '0 4px 16px rgba(0, 0, 0, 0.08)',
                        }}
                    >
                        <Result
                            status="warning"
                            icon={<BugOutlined style={{ color: '#faad14' }} />}
                            title="Oops! Something went wrong"
                            subTitle={
                                <Space direction="vertical" size={12}>
                                    <Text type="secondary">
                                        We're sorry, but something unexpected happened. Please try refreshing
                                        the page or going back to the home page.
                                    </Text>
                                    {process.env.NODE_ENV === 'development' && this.state.error && (
                                        <Card
                                            size="small"
                                            style={{
                                                background: '#fff2f0',
                                                borderColor: '#ffccc7',
                                                textAlign: 'left',
                                            }}
                                        >
                                            <Paragraph
                                                code
                                                copyable
                                                style={{ margin: 0, fontSize: 12 }}
                                            >
                                                {this.state.error.toString()}
                                            </Paragraph>
                                        </Card>
                                    )}
                                </Space>
                            }
                            extra={
                                <Space>
                                    <Button
                                        type="primary"
                                        icon={<ReloadOutlined />}
                                        onClick={this.handleReload}
                                    >
                                        Refresh Page
                                    </Button>
                                    <Button icon={<HomeOutlined />} onClick={this.handleGoHome}>
                                        Go Home
                                    </Button>
                                </Space>
                            }
                        />
                    </Card>
                </div>
            );
        }

        return this.props.children;
    }
}

/**
 * Wrapper for pages with error boundary
 */
export const withErrorBoundary = <P extends object>(
    WrappedComponent: React.ComponentType<P>,
    fallback?: ReactNode
) => {
    return (props: P) => (
        <ErrorBoundary fallback={fallback}>
            <WrappedComponent {...props} />
        </ErrorBoundary>
    );
};

/**
 * Simple inline error display
 */
export const InlineError: React.FC<{
    message?: string;
    onRetry?: () => void;
}> = ({ message = 'Failed to load', onRetry }) => (
    <Card
        size="small"
        style={{
            background: '#fff2f0',
            borderColor: '#ffccc7',
            borderRadius: 8,
        }}
    >
        <Space>
            <Text type="danger">{message}</Text>
            {onRetry && (
                <Button type="link" size="small" onClick={onRetry}>
                    Retry
                </Button>
            )}
        </Space>
    </Card>
);

export default { ErrorBoundary, withErrorBoundary, InlineError };
