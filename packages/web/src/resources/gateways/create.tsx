import React from 'react';
import { Create, useForm } from '@refinedev/antd';
import { Form, Input, InputNumber, Select, Switch, DatePicker, Card } from 'antd';
import type { IResourceComponentsProps } from '@refinedev/core';
import type { IGateway } from './list';
import dayjs from 'dayjs';

const { TextArea } = Input;

export const GatewayCreate: React.FC<IResourceComponentsProps> = () => {
  const { formProps, saveButtonProps } = useForm<IGateway>();

  return (
    <Create saveButtonProps={saveButtonProps}>
      <Form {...formProps} layout="vertical">
        <Card title="Basic Information" style={{ marginBottom: 16 }}>
          <Form.Item
            label="Gateway Name"
            name="name"
            rules={[
              {
                required: true,
                message: 'Gateway name is required',
              },
            ]}
          >
            <Input placeholder="e.g., MTN Lagos Primary" />
          </Form.Item>

          <Form.Item
            label="Gateway Code"
            name="code"
            rules={[
              {
                required: true,
                message: 'Gateway code is required',
              },
              {
                pattern: /^[A-Z0-9-]+$/,
                message: 'Code must contain only uppercase letters, numbers, and hyphens',
              },
            ]}
          >
            <Input placeholder="e.g., GTW-NG-MTN-LAG-01" />
          </Form.Item>

          <Form.Item label="Description" name="description">
            <TextArea rows={3} placeholder="Gateway description" />
          </Form.Item>
        </Card>

        <Card title="Network Configuration" style={{ marginBottom: 16 }}>
          <Form.Item
            label="IP Address"
            name="ip_address"
            rules={[
              {
                required: true,
                message: 'IP address is required',
              },
              {
                pattern:
                  /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/,
                message: 'Please enter a valid IP address',
              },
            ]}
          >
            <Input placeholder="e.g., 10.20.30.40" />
          </Form.Item>

          <Form.Item
            label="Port"
            name="port"
            initialValue={5060}
            rules={[
              {
                required: true,
                message: 'Port is required',
              },
            ]}
          >
            <InputNumber min={1} max={65535} placeholder="5060" style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            label="Protocol"
            name="protocol"
            initialValue="UDP"
            rules={[
              {
                required: true,
                message: 'Protocol is required',
              },
            ]}
          >
            <Select placeholder="Select protocol">
              <Select.Option value="UDP">UDP</Select.Option>
              <Select.Option value="TCP">TCP</Select.Option>
              <Select.Option value="TLS">TLS</Select.Option>
            </Select>
          </Form.Item>
        </Card>

        <Card title="Carrier Information" style={{ marginBottom: 16 }}>
          <Form.Item label="Carrier Name" name="carrier_name">
            <Input placeholder="e.g., MTN Nigeria" />
          </Form.Item>

          <Form.Item label="Carrier Type" name="carrier_type">
            <Select placeholder="Select carrier type">
              <Select.Option value="MNO">MNO (Mobile Network Operator)</Select.Option>
              <Select.Option value="MVNO">MVNO</Select.Option>
              <Select.Option value="ICL">ICL (Interconnect Clearinghouse)</Select.Option>
              <Select.Option value="International">International</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item label="Region" name="region">
            <Input placeholder="e.g., Lagos, Abuja, Asaba" />
          </Form.Item>

          <Form.Item label="Country Code" name="country_code" initialValue="NGA">
            <Input placeholder="NGA" maxLength={3} />
          </Form.Item>
        </Card>

        <Card title="Gateway Classification" style={{ marginBottom: 16 }}>
          <Form.Item
            label="Gateway Type"
            name="gateway_type"
            rules={[
              {
                required: true,
                message: 'Gateway type is required',
              },
            ]}
          >
            <Select placeholder="Select gateway type">
              <Select.Option value="ingress">Ingress</Select.Option>
              <Select.Option value="egress">Egress</Select.Option>
              <Select.Option value="transit">Transit</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item label="Direction" name="direction" initialValue="bidirectional">
            <Select placeholder="Select direction">
              <Select.Option value="inbound">Inbound Only</Select.Option>
              <Select.Option value="outbound">Outbound Only</Select.Option>
              <Select.Option value="bidirectional">Bidirectional</Select.Option>
            </Select>
          </Form.Item>
        </Card>

        <Card title="Detection Configuration" style={{ marginBottom: 16 }}>
          <Form.Item
            label="Fraud Threshold"
            name="fraud_threshold"
            tooltip="Number of distinct callers to same B-number before triggering alert"
            initialValue={5}
          >
            <InputNumber min={1} max={100} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            label="Max Concurrent Calls"
            name="max_concurrent_calls"
            initialValue={1000}
          >
            <InputNumber min={0} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            label="Max Calls Per Second"
            name="max_calls_per_second"
            initialValue={100}
          >
            <InputNumber min={0} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            label="Enable Monitoring"
            name="is_monitored"
            valuePropName="checked"
            initialValue={true}
          >
            <Switch />
          </Form.Item>
        </Card>

        <Card title="Status" style={{ marginBottom: 16 }}>
          <Form.Item
            label="Status"
            name="status"
            initialValue="active"
            rules={[
              {
                required: true,
                message: 'Status is required',
              },
            ]}
          >
            <Select placeholder="Select status">
              <Select.Option value="active">Active</Select.Option>
              <Select.Option value="inactive">Inactive</Select.Option>
              <Select.Option value="suspended">Suspended</Select.Option>
              <Select.Option value="blacklisted">Blacklisted</Select.Option>
            </Select>
          </Form.Item>
        </Card>

        <Card title="NCC Compliance" style={{ marginBottom: 16 }}>
          <Form.Item label="NCC License Number" name="ncc_license_number">
            <Input placeholder="NCC license number" />
          </Form.Item>

          <Form.Item
            label="License Expiry Date"
            name="license_expiry_date"
            getValueProps={(value) => ({
              value: value ? dayjs(value) : undefined,
            })}
          >
            <DatePicker style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            label="NCC Compliant"
            name="is_ncc_compliant"
            valuePropName="checked"
            initialValue={true}
          >
            <Switch />
          </Form.Item>
        </Card>

        <Card title="Technical Contact">
          <Form.Item label="Contact Name" name="technical_contact_name">
            <Input placeholder="Technical contact name" />
          </Form.Item>

          <Form.Item
            label="Contact Email"
            name="technical_contact_email"
            rules={[
              {
                type: 'email',
                message: 'Please enter a valid email',
              },
            ]}
          >
            <Input placeholder="email@example.com" />
          </Form.Item>

          <Form.Item label="Contact Phone" name="technical_contact_phone">
            <Input placeholder="+234XXXXXXXXXX" />
          </Form.Item>
        </Card>
      </Form>
    </Create>
  );
};
