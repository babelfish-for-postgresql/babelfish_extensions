-- Intermediate JSON result exceeds 4000 characters in length
-- Expect no error
EXEC BABEL_5054_vu_prepare_p1
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p1
GO

-- Intermediate JSON result exceeds 4000 characters in length
-- Expect no error
EXEC BABEL_5054_vu_prepare_p2
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p2
GO

-- Intermediate JSON result exceeds 4000 characters in length
-- Expect no error
EXEC BABEL_5054_vu_prepare_p3
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p3
GO

-- JSON in a single result cell exceeds 4000 characters in length
-- Expect no error
EXEC BABEL_5054_vu_prepare_p4
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p4
GO

-- JSON in a single result cell exceeds 4000 characters in length
-- Expect no error
EXEC BABEL_5054_vu_prepare_p5
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p5
GO

-- JSON in a single result cell exceeds 4000 characters in length
-- Expect no error
EXEC BABEL_5054_vu_prepare_p6
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p6
GO

-- long JSON exceeding 4000 characters as input
-- Expect no error
DECLARE @json NVARCHAR(MAX) = N'{
        "Warehouse": {
            "WarehouseID": {
                "ScanDate": "2023-01-03",
                "FacilityCode": "WHSE01",
                "InventoryType": "ProductType",
                "ValidFrom": "2023-01-03",
                "ValidTo": "2023-02-28",
                "Zones": "ZONE_A,ZONE_B,ZONE_C",
                "Sections": "SEC1,SEC2,SEC3",
                "IsActive": "true",
                "RequestMode": "STANDARD",
                "MaxResults": "100",
                "LocationID": "LOC123",
                "TrackingEnabled": "true",
                "BatchNumber": "BTH2023001",
                "SensorID": "1234",
                "ReadingID": "5678"
            },
            "SystemMetadata": {
                "TotalDays": "30",
                "TotalRecords": "15",
                "HasMoreRecords": "false",
                "IsComplete": "true",
                "LastUpdate": "2023-01-03T14:30:00",
                "ProcessingTime": "1.5",
                "DataQuality": "HIGH"
            },
            "FacilityDailyStatusArray": {
                "FacilityDailyStatus": [
                    {
                        "Date": "2023-01-03",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "100",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "800",
                        "AllocatedSpace": "100",
                        "TotalUsed": "200",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "8",
                        "OperationalHours": "24",
                        "PowerConsumption": "450.75",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    },
                    {
                        "Date": "2023-01-04",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "150",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "750",
                        "AllocatedSpace": "150",
                        "TotalUsed": "250",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "10",
                        "OperationalHours": "24",
                        "PowerConsumption": "475.25",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    },
                    {
                        "Date": "2023-01-05",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "150",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "750",
                        "AllocatedSpace": "150",
                        "TotalUsed": "250",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "10",
                        "OperationalHours": "24",
                        "PowerConsumption": "475.25",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    },
                    {
                        "Date": "2023-01-06",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "150",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "750",
                        "AllocatedSpace": "150",
                        "TotalUsed": "250",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "10",
                        "OperationalHours": "24",
                        "PowerConsumption": "475.25",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    },
                    {
                        "Date": "2023-01-07",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "150",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "750",
                        "AllocatedSpace": "150",
                        "TotalUsed": "250",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "10",
                        "OperationalHours": "24",
                        "PowerConsumption": "475.25",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    },
                    {
                        "Date": "2023-01-08",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "150",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "750",
                        "AllocatedSpace": "150",
                        "TotalUsed": "250",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "10",
                        "OperationalHours": "24",
                        "PowerConsumption": "475.25",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    },
                    {
                        "Date": "2023-01-09",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "150",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "750",
                        "AllocatedSpace": "150",
                        "TotalUsed": "250",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "10",
                        "OperationalHours": "24",
                        "PowerConsumption": "475.25",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    },
                    {
                        "Date": "2023-01-10",
                        "IsOperational": "true",
                        "MaintenanceMode": "false",
                        "MinCapacity": "0",
                        "MaxCapacity": "1000",
                        "RestrictedAccess": "false",
                        "MinStaffing": "5",
                        "MinStorageTime": "24",
                        "MaxStorageTime": "720",
                        "ReservedSpace": "150",
                        "MaintenanceSpace": "50",
                        "AvailableSpace": "750",
                        "AllocatedSpace": "150",
                        "TotalUsed": "250",
                        "TotalCapacity": "1000",
                        "BlockedSpace": "50",
                        "PhysicalCapacity": "1000",
                        "Adjustment": "0",
                        "StaffingLevel": "10",
                        "OperationalHours": "24",
                        "PowerConsumption": "475.25",
                        "AlertLevel": "GREEN",
                        "MaintenanceScheduled": "false"
                    }
                ]
            },
            "StorageTypeArray": {
                "StorageType": [
                    {
                        "StorageCode": "COLD",
                        "StorageName": "Cold Storage",
                        "IsTemperatureControlled": "true",
                        "IsHazmat": "false",
                        "Zone": "ZONE_A",
                        "MaxWeight": "5000",
                        "StorageClass": "CLASS_A",
                        "SecurityLevel": "HIGH",
                        "RequiresSpecialHandling": "true",
                        "DailyMetricsArray": {
                            "DailyMetrics": [
                                {
                                    "Date": "2023-01-03",
                                    "IsOperational": "true",
                                    "MaintenanceMode": "false",
                                    "MinCapacity": "0",
                                    "MaxCapacity": "500",
                                    "RestrictedAccess": "false",
                                    "MinStaffing": "2",
                                    "AvailableSpace": "400",
                                    "AllocatedSpace": "50",
                                    "TotalUsed": "100",
                                    "TotalCapacity": "500",
                                    "Temperature": "-18.5",
                                    "Humidity": "45",
                                    "PowerStatus": "NORMAL",
                                    "BackupPower": "READY",
                                    "LastMaintenance": "2023-01-01",
                                    "NextMaintenance": "2023-02-01",
                                    "AlertCount": "0",
                                    "DoorOpenCount": "24",
                                    "TemperatureBreaches": "0",
                                    "ProductRotationStatus": "NORMAL"
                                },
                                {
                                    "Date": "2023-01-04",
                                    "IsOperational": "true",
                                    "MaintenanceMode": "false",
                                    "MinCapacity": "0",
                                    "MaxCapacity": "500",
                                    "RestrictedAccess": "false",
                                    "MinStaffing": "2",
                                    "AvailableSpace": "380",
                                    "AllocatedSpace": "70",
                                    "TotalUsed": "120",
                                    "TotalCapacity": "500",
                                    "Temperature": "-18.2",
                                    "Humidity": "44",
                                    "PowerStatus": "NORMAL",
                                    "BackupPower": "READY",
                                    "LastMaintenance": "2023-01-01",
                                    "NextMaintenance": "2023-02-01",
                                    "AlertCount": "1",
                                    "DoorOpenCount": "28",
                                    "TemperatureBreaches": "0",
                                    "ProductRotationStatus": "NORMAL"
                                }
                            ]
                        }
                    },
                    {
                        "StorageCode": "FRSH",
                        "StorageName": "Fresh Storage",
                        "IsTemperatureControlled": "true",
                        "IsHazmat": "false",
                        "Zone": "ZONE_B",
                        "MaxWeight": "3000",
                        "StorageClass": "CLASS_B",
                        "SecurityLevel": "MEDIUM",
                        "RequiresSpecialHandling": "true",
                        "DailyMetricsArray": {
                            "DailyMetrics": [
                                {
                                    "Date": "2023-01-03",
                                    "IsOperational": "true",
                                    "MaintenanceMode": "false",
                                    "MinCapacity": "0",
                                    "MaxCapacity": "300",
                                    "RestrictedAccess": "false",
                                    "MinStaffing": "2",
                                    "AvailableSpace": "200",
                                    "AllocatedSpace": "50",
                                    "TotalUsed": "100",
                                    "TotalCapacity": "300",
                                    "Temperature": "4.2",
                                    "Humidity": "65",
                                    "PowerStatus": "NORMAL",
                                    "BackupPower": "READY",
                                    "LastMaintenance": "2023-01-02",
                                    "NextMaintenance": "2023-02-02",
                                    "AlertCount": "0",
                                    "DoorOpenCount": "35",
                                    "TemperatureBreaches": "0",
                                    "ProductRotationStatus": "NORMAL"
                                }
                            ]
                        }
                    },
                    {
                        "StorageCode": "HAZMT",
                        "StorageName": "Hazmat Storage",
                        "IsTemperatureControlled": "true",
                        "IsHazmat": "true",
                        "Zone": "ZONE_C",
                        "MaxWeight": "2000",
                        "StorageClass": "CLASS_H",
                        "SecurityLevel": "MAXIMUM",
                        "RequiresSpecialHandling": "true",
                        "DailyMetricsArray": {
                            "DailyMetrics": [
                                {
                                    "Date": "2023-01-03",
                                    "IsOperational": "true",
                                    "MaintenanceMode": "false",
                                    "MinCapacity": "0",
                                    "MaxCapacity": "200",
                                    "RestrictedAccess": "true",
                                    "MinStaffing": "3",
                                    "AvailableSpace": "150",
                                    "AllocatedSpace": "30",
                                    "TotalUsed": "50",
                                    "TotalCapacity": "200",
                                    "Temperature": "21.0",
                                    "Humidity": "40",
                                    "PowerStatus": "NORMAL",
                                    "BackupPower": "READY",
                                    "LastMaintenance": "2023-01-01",
                                    "NextMaintenance": "2023-01-15",
                                    "AlertCount": "0",
                                    "DoorOpenCount": "12",
                                    "TemperatureBreaches": "0",
                                    "ProductRotationStatus": "NORMAL",
                                    "HazmatIncidents": "0",
                                    "SafetyInspectionStatus": "PASSED",
                                    "EmergencyResponseReady": "true"
                                }
                            ]
                        }
                    }
                ]
            },
            "EnvironmentalMetrics": {
                "AirQuality": "GOOD",
                "CO2Levels": "450",
                "NoiseLevel": "65",
                "LightingLevel": "800",
                "WaterUsage": "1250",
                "WasteManagement": "OPTIMAL",
                "RecyclingRate": "85.5"
            },
            "SecurityStatus": {
                "AccessControlStatus": "ACTIVE",
                "SecurityPersonnel": "4",
                "CameraStatus": "OPERATIONAL",
                "LastIncident": "2022-12-15",
                "ThreatLevel": "LOW",
                "PerimeterStatus": "SECURE"
            }
        }
    }'
EXEC BABEL_5054_vu_prepare_p7 @jsonInventory = @json
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p7
GO


-- long JSON exceeding 4000 characters as input
-- Expect no error
DECLARE @json NVARCHAR(MAX) = N'{
        "Factory": {
            "ProductionID": {
                "TimeStamp": "2023-01-03T00:00:00",
                "PlantCode": "MFGP01",
                "ShiftCode": "SHIFT_A",
                "ProductionLine": "LINE_001",
                "BatchStart": "2023-01-03T06:00:00",
                "BatchEnd": "2023-01-03T14:00:00",
                "ProductCategories": "AUTOMOTIVE,ELECTRONICS",
                "QualityLevel": "PREMIUM",
                "IsActive": "true",
                "MonitoringMode": "REAL_TIME",
                "SamplingRate": "60",
                "SupervisorID": "SUP_123",
                "CertificationLevel": "ISO9001",
                "ControlSystemVersion": "5.2.1"
            },
            "SystemStatus": {
                "MonitoringPeriod": "28",
                "DataPoints": "1440",
                "DataIntegrity": "99.98",
                "LastBackup": "2023-01-02T23:00:00",
                "SystemHealth": "OPTIMAL",
                "AlertStatus": "NORMAL",
                "MaintenanceWindow": "SCHEDULED",
                "CalibrationStatus": "VALID"
            },
            "ProductionLineStatusArray": {
                "ProductionLineStatus": [
                    {
                        "DateTime": "2023-01-03T06:00:00",
                        "OperationalStatus": "RUNNING",
                        "CurrentSpeed": "95.5",
                        "TargetSpeed": "100.0",
                        "DefectRate": "0.12",
                        "ProductionRate": "857",
                        "DowntimeMinutes": "0",
                        "WorkerCount": "12",
                        "EnergyConsumption": "450.75",
                        "MaterialEfficiency": "98.5",
                        "QualityScore": "99.2",
                        "TemperatureZone1": "22.5",
                        "TemperatureZone2": "23.1",
                        "HumidityZone1": "45",
                        "HumidityZone2": "47",
                        "VibrationLevel": "0.15",
                        "NoiseLevel": "72.5",
                        "PressureReading": "101.3",
                        "SafetyIncidents": "0",
                        "MaintenanceAlerts": "0"
                    },
                    {
                        "DateTime": "2023-01-03T07:00:00",
                        "OperationalStatus": "RUNNING",
                        "CurrentSpeed": "97.2",
                        "TargetSpeed": "100.0",
                        "DefectRate": "0.15",
                        "ProductionRate": "862",
                        "DowntimeMinutes": "5",
                        "WorkerCount": "12",
                        "EnergyConsumption": "455.25",
                        "MaterialEfficiency": "98.2",
                        "QualityScore": "99.1",
                        "TemperatureZone1": "22.7",
                        "TemperatureZone2": "23.3",
                        "HumidityZone1": "46",
                        "HumidityZone2": "48",
                        "VibrationLevel": "0.17",
                        "NoiseLevel": "73.1",
                        "PressureReading": "101.2",
                        "SafetyIncidents": "0",
                        "MaintenanceAlerts": "1"
                    }
                ]
            },
            "MachineStatusArray": {
                "MachineStatus": [
                    {
                        "MachineCode": "ROB01",
                        "MachineName": "Robotic Arm Assembly",
                        "MachineType": "ROBOTICS",
                        "Zone": "ZONE_A",
                        "InstallDate": "2022-01-15",
                        "LastMaintenance": "2022-12-15",
                        "CertificationExpiry": "2024-01-15",
                        "HourlyMetricsArray": {
                            "HourlyMetrics": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.5",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "0",
                                    "ProductCount": "79",
                                    "RejectCount": "1",
                                    "PowerConsumption": "2.75",
                                    "MotorTemperature": "42.5",
                                    "OilPressure": "95.5",
                                    "VibrationReading": "0.12",
                                    "AccuracyScore": "99.8",
                                    "WearLevel": "15.5",
                                    "MaintenanceScore": "98.5",
                                    "PerformanceIndex": "97.2",
                                    "QualityIndex": "99.5",
                                    "AvailabilityIndex": "99.8",
                                    "OEEScore": "96.5"
                                },
                                {
                                    "DateTime": "2023-01-03T07:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T08:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T09:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T10:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T11:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                }
                            ]
                        }
                    },
                    {
                        "MachineCode": "CNC01",
                        "MachineName": "CNC Milling Station",
                        "MachineType": "CNC",
                        "Zone": "ZONE_B",
                        "InstallDate": "2021-06-20",
                        "LastMaintenance": "2022-12-20",
                        "CertificationExpiry": "2024-06-20",
                        "HourlyMetricsArray": {
                            "HourlyMetrics": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "32.5",
                                    "TargetCycleTime": "32.0",
                                    "ErrorCount": "0",
                                    "ProductCount": "110",
                                    "RejectCount": "2",
                                    "PowerConsumption": "4.25",
                                    "SpindleTemperature": "55.5",
                                    "CoolantLevel": "92.5",
                                    "ToolWear": "25.5",
                                    "AccuracyScore": "99.5",
                                    "SurfaceFinish": "0.8",
                                    "MaintenanceScore": "97.5",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "98.9",
                                    "AvailabilityIndex": "99.5",
                                    "OEEScore": "95.2"
                                }
                            ]
                        }
                    }
                ]
            },
            "QualityMetrics": {
                "BatchDefectRate": "0.14",
                "FirstPassYield": "98.5",
                "ReworkRate": "1.2",
                "ScrapRate": "0.3",
                "CustomerComplaints": "0",
                "QualityAuditScore": "95.5",
                "ProcessCapabilityIndex": "1.45"
            },
            "ResourceConsumption": {
                "ElectricityUsage": "2750.5",
                "WaterUsage": "850.2",
                "CompressedAir": "1200.5",
                "RawMaterialUsage": "2500.0",
                "WasteGenerated": "45.5",
                "RecycledMaterial": "40.2",
                "CarbonFootprint": "1250.75"
            }
        }
    }'
EXEC BABEL_5054_vu_prepare_p8 @jsonProduction = @json
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p8
GO


-- long JSON exceeding 4000 characters as input
-- Expect no error
DECLARE @json NVARCHAR(MAX) = N'{
        "Factory": {
            "ProductionID": {
                "TimeStamp": "2023-01-03T00:00:00",
                "PlantCode": "MFGP01",
                "ShiftCode": "SHIFT_A",
                "ProductionLine": "LINE_001",
                "BatchStart": "2023-01-03T06:00:00",
                "BatchEnd": "2023-01-03T14:00:00",
                "ProductCategories": "AUTOMOTIVE,ELECTRONICS",
                "QualityLevel": "PREMIUM",
                "IsActive": "true",
                "MonitoringMode": "REAL_TIME",
                "SamplingRate": "60",
                "SupervisorID": "SUP_123",
                "CertificationLevel": "ISO9001",
                "ControlSystemVersion": "5.2.1"
            },
            "SystemStatus": {
                "MonitoringPeriod": "28",
                "DataPoints": "1440",
                "DataIntegrity": "99.98",
                "LastBackup": "2023-01-02T23:00:00",
                "SystemHealth": "OPTIMAL",
                "AlertStatus": "NORMAL",
                "MaintenanceWindow": "SCHEDULED",
                "CalibrationStatus": "VALID"
            },
            "ProductionLineStatusArray": {
                "ProductionLineStatus": [
                    {
                        "DateTime": "2023-01-03T06:00:00",
                        "OperationalStatus": "RUNNING",
                        "CurrentSpeed": "95.5",
                        "TargetSpeed": "100.0",
                        "DefectRate": "0.12",
                        "ProductionRate": "857",
                        "DowntimeMinutes": "0",
                        "WorkerCount": "12",
                        "EnergyConsumption": "450.75",
                        "MaterialEfficiency": "98.5",
                        "QualityScore": "99.2",
                        "TemperatureZone1": "22.5",
                        "TemperatureZone2": "23.1",
                        "HumidityZone1": "45",
                        "HumidityZone2": "47",
                        "VibrationLevel": "0.15",
                        "NoiseLevel": "72.5",
                        "PressureReading": "101.3",
                        "SafetyIncidents": "0",
                        "MaintenanceAlerts": "0"
                    },
                    {
                        "DateTime": "2023-01-03T07:00:00",
                        "OperationalStatus": "RUNNING",
                        "CurrentSpeed": "97.2",
                        "TargetSpeed": "100.0",
                        "DefectRate": "0.15",
                        "ProductionRate": "862",
                        "DowntimeMinutes": "5",
                        "WorkerCount": "12",
                        "EnergyConsumption": "455.25",
                        "MaterialEfficiency": "98.2",
                        "QualityScore": "99.1",
                        "TemperatureZone1": "22.7",
                        "TemperatureZone2": "23.3",
                        "HumidityZone1": "46",
                        "HumidityZone2": "48",
                        "VibrationLevel": "0.17",
                        "NoiseLevel": "73.1",
                        "PressureReading": "101.2",
                        "SafetyIncidents": "0",
                        "MaintenanceAlerts": "1"
                    }
                ]
            },
            "MachineStatusArray": {
                "MachineStatus": [
                    {
                        "MachineCode": "ROB01",
                        "MachineName": "Robotic Arm Assembly",
                        "MachineType": "ROBOTICS",
                        "Zone": "ZONE_A",
                        "InstallDate": "2022-01-15",
                        "LastMaintenance": "2022-12-15",
                        "CertificationExpiry": "2024-01-15",
                        "HourlyMetricsArray": {
                            "HourlyMetrics": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.5",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "0",
                                    "ProductCount": "79",
                                    "RejectCount": "1",
                                    "PowerConsumption": "2.75",
                                    "MotorTemperature": "42.5",
                                    "OilPressure": "95.5",
                                    "VibrationReading": "0.12",
                                    "AccuracyScore": "99.8",
                                    "WearLevel": "15.5",
                                    "MaintenanceScore": "98.5",
                                    "PerformanceIndex": "97.2",
                                    "QualityIndex": "99.5",
                                    "AvailabilityIndex": "99.8",
                                    "OEEScore": "96.5"
                                },
                                {
                                    "DateTime": "2023-01-03T07:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T08:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T09:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T10:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                },
                                {
                                    "DateTime": "2023-01-03T11:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "45.8",
                                    "TargetCycleTime": "45.0",
                                    "ErrorCount": "1",
                                    "ProductCount": "77",
                                    "RejectCount": "2",
                                    "PowerConsumption": "2.82",
                                    "MotorTemperature": "43.1",
                                    "OilPressure": "95.2",
                                    "VibrationReading": "0.14",
                                    "AccuracyScore": "99.7",
                                    "WearLevel": "15.7",
                                    "MaintenanceScore": "98.2",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "99.3",
                                    "AvailabilityIndex": "99.7",
                                    "OEEScore": "95.8"
                                }
                            ]
                        }
                    },
                    {
                        "MachineCode": "CNC01",
                        "MachineName": "CNC Milling Station",
                        "MachineType": "CNC",
                        "Zone": "ZONE_B",
                        "InstallDate": "2021-06-20",
                        "LastMaintenance": "2022-12-20",
                        "CertificationExpiry": "2024-06-20",
                        "HourlyMetricsArray": {
                            "HourlyMetrics": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "CycleTime": "32.5",
                                    "TargetCycleTime": "32.0",
                                    "ErrorCount": "0",
                                    "ProductCount": "110",
                                    "RejectCount": "2",
                                    "PowerConsumption": "4.25",
                                    "SpindleTemperature": "55.5",
                                    "CoolantLevel": "92.5",
                                    "ToolWear": "25.5",
                                    "AccuracyScore": "99.5",
                                    "SurfaceFinish": "0.8",
                                    "MaintenanceScore": "97.5",
                                    "PerformanceIndex": "96.8",
                                    "QualityIndex": "98.9",
                                    "AvailabilityIndex": "99.5",
                                    "OEEScore": "95.2"
                                }
                            ]
                        }
                    }
                ]
            },
            "QualityMetrics": {
                "BatchDefectRate": "0.14",
                "FirstPassYield": "98.5",
                "ReworkRate": "1.2",
                "ScrapRate": "0.3",
                "CustomerComplaints": "0",
                "QualityAuditScore": "95.5",
                "ProcessCapabilityIndex": "1.45"
            },
            "ResourceConsumption": {
                "ElectricityUsage": "2750.5",
                "WaterUsage": "850.2",
                "CompressedAir": "1200.5",
                "RawMaterialUsage": "2500.0",
                "WasteGenerated": "45.5",
                "RecycledMaterial": "40.2",
                "CarbonFootprint": "1250.75"
            }
        }
    }'
EXEC BABEL_5054_vu_prepare_p9 @json = @json
GO
DROP PROCEDURE BABEL_5054_vu_prepare_p9
GO


-- long JSON exceeding 4000 characters in create view
-- Expect no error
SELECT * FROM BABEL_5054_vu_prepare_v1
GO
DROP VIEW BABEL_5054_vu_prepare_v1
GO


-- long JSON exceeding 4000 characters in create view
-- Expect no error
SELECT * FROM BABEL_5054_vu_prepare_v2
GO
DROP VIEW BABEL_5054_vu_prepare_v2
GO