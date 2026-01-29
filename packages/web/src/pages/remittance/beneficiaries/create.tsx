import { Create, useForm } from '@refinedev/antd';
import { Form, Input, Select, Card, Row, Col, Typography, Alert, Spin, message } from 'antd';
import { useState } from 'react';
import { useList, useCustomMutation } from '@refinedev/core';

import type { CreateBeneficiaryInput, NigerianBank } from '@/types';

const { Text } = Typography;

export const BeneficiaryCreate: React.FC = () => {
    const [verifying, setVerifying] = useState(false);
    const [accountName, setAccountName] = useState<string | null>(null);

    const { formProps, saveButtonProps, form } = useForm<CreateBeneficiaryInput>({
        resource: 'beneficiaries',
        action: 'create',
        redirect: 'list',
    });

    const { data: banksData } = useList<NigerianBank>({
        resource: 'nigerian_banks',
        filters: [{ field: 'is_active', operator: 'eq', value: true }],
        pagination: { mode: 'off' },
        meta: {
            fields: ['id', 'code', 'name', 'short_name'],
        },
    });

    const { mutate: verifyAccount } = useCustomMutation();

    const handleVerifyAccount = async () => {
        const bankCode = form.getFieldValue('bank_code');
        const accountNumber = form.getFieldValue('account_number');

        if (!bankCode || !accountNumber || accountNumber.length !== 10) {
            message.warning('Please enter valid bank code and 10-digit account number');
            return;
        }

        setVerifying(true);
        setAccountName(null);

        verifyAccount({
            url: '',
            method: 'post',
            values: { bank_code: bankCode, account_number: accountNumber },
            meta: {
                gqlMutation: `
          mutation VerifyBankAccount($bank_code: String!, $account_number: String!) {
            verifyBankAccount(bank_code: $bank_code, account_number: $account_number) {
              success
              data
            }
          }
        `,
            },
        }, {
            onSuccess: (data: any) => {
                setVerifying(false);
                if (data?.data?.verifyBankAccount?.success) {
                    const name = data.data.verifyBankAccount.data?.account_name;
                    setAccountName(name);
                    form.setFieldValue('account_name', name);
                    message.success('Account verified!');
                } else {
                    message.error('Account verification failed');
                }
            },
            onError: () => {
                setVerifying(false);
                message.error('Verification failed');
            },
        });
    };

    const banks = banksData?.data || [];

    return (
        <Create saveButtonProps={saveButtonProps}>
            <Form {...formProps} layout="vertical">
                <Row gutter={16}>
                    <Col span={12}>
                        <Card title="Personal Information">
                            <Row gutter={12}>
                                <Col span={12}>
                                    <Form.Item
                                        label="First Name"
                                        name="first_name"
                                        rules={[{ required: true }]}
                                    >
                                        <Input placeholder="First name" />
                                    </Form.Item>
                                </Col>
                                <Col span={12}>
                                    <Form.Item
                                        label="Last Name"
                                        name="last_name"
                                        rules={[{ required: true }]}
                                    >
                                        <Input placeholder="Last name" />
                                    </Form.Item>
                                </Col>
                            </Row>

                            <Form.Item
                                label="Middle Name"
                                name="middle_name"
                            >
                                <Input placeholder="Middle name (optional)" />
                            </Form.Item>

                            <Form.Item
                                label="Relationship"
                                name="relationship"
                            >
                                <Select
                                    placeholder="Select relationship"
                                    options={[
                                        { label: 'Self', value: 'Self' },
                                        { label: 'Spouse', value: 'Spouse' },
                                        { label: 'Parent', value: 'Parent' },
                                        { label: 'Child', value: 'Child' },
                                        { label: 'Sibling', value: 'Sibling' },
                                        { label: 'Friend', value: 'Friend' },
                                        { label: 'Business', value: 'Business' },
                                        { label: 'Other', value: 'Other' },
                                    ]}
                                />
                            </Form.Item>

                            <Form.Item label="Phone Number" name="phone_number">
                                <Input placeholder="+234..." />
                            </Form.Item>

                            <Form.Item label="Email" name="email">
                                <Input type="email" placeholder="email@example.com" />
                            </Form.Item>
                        </Card>
                    </Col>

                    <Col span={12}>
                        <Card title="Bank Details">
                            <Form.Item
                                label="Bank"
                                name="bank_code"
                                rules={[{ required: true, message: 'Please select a bank' }]}
                            >
                                <Select
                                    showSearch
                                    placeholder="Select bank"
                                    optionFilterProp="label"
                                    options={banks.map((bank: any) => ({
                                        label: bank.name,
                                        value: bank.code,
                                    }))}
                                    onChange={() => {
                                        setAccountName(null);
                                        form.setFieldValue('account_name', undefined);
                                    }}
                                />
                            </Form.Item>

                            <Form.Item
                                label="Account Number"
                                name="account_number"
                                rules={[
                                    { required: true, message: 'Please enter account number' },
                                    { len: 10, message: 'Account number must be 10 digits' },
                                    { pattern: /^\d+$/, message: 'Account number must be numeric' },
                                ]}
                            >
                                <Input
                                    placeholder="10-digit account number"
                                    maxLength={10}
                                    onChange={() => {
                                        setAccountName(null);
                                        form.setFieldValue('account_name', undefined);
                                    }}
                                    addonAfter={
                                        verifying ? (
                                            <Spin size="small" />
                                        ) : (
                                            <a onClick={handleVerifyAccount}>Verify</a>
                                        )
                                    }
                                />
                            </Form.Item>

                            {accountName && (
                                <Alert
                                    message="Account Verified"
                                    description={<Text strong>{accountName}</Text>}
                                    type="success"
                                    showIcon
                                    style={{ marginBottom: 16 }}
                                />
                            )}

                            <Form.Item name="account_name" hidden>
                                <Input />
                            </Form.Item>
                        </Card>
                    </Col>
                </Row>
            </Form>
        </Create>
    );
};

export default BeneficiaryCreate;
