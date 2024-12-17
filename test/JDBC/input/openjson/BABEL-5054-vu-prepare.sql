CREATE PROCEDURE BABEL_5054_vu_prepare_p1
AS
BEGIN
    DECLARE @jsonInventory NVARCHAR(MAX) = N'{
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
    SELECT 
        WarehouseID.FacilityCode AS FacilityCode,
        StorageArr.StorageCode AS Storage_Code,
        [Date] AS Metric_Date,
        AvailableSpace AS Available_Space,
        TotalUsed AS Total_Used,
        IsOperational AS Is_Operational,
        Temperature AS Storage_Temp,
        Humidity AS Storage_Humidity
    FROM OPENJSON(@jsonInventory) WITH (
        WarehouseID NVARCHAR(MAX) '$.Warehouse.WarehouseID' AS JSON,
        StorageTypeArray NVARCHAR(MAX) '$.Warehouse.StorageTypeArray' AS JSON
    ) AS [Warehouse]
    OUTER APPLY OPENJSON([Warehouse].WarehouseID) WITH (
        FacilityCode VARCHAR(15) '$.FacilityCode'
    ) AS WarehouseID
    OUTER APPLY OPENJSON([Warehouse].StorageTypeArray) WITH (
        StorageType NVARCHAR(MAX) '$.StorageType' AS JSON
    ) AS Storage
    OUTER APPLY OPENJSON(Storage.StorageType) WITH (
        StorageCode VARCHAR(6) '$.StorageCode',
        DailyMetricsArray NVARCHAR(MAX) '$.DailyMetricsArray' AS JSON
    ) AS StorageArr
    OUTER APPLY OPENJSON(StorageArr.DailyMetricsArray) WITH (
        DailyMetrics NVARCHAR(MAX) '$.DailyMetrics' AS JSON
    ) AS Metrics
    OUTER APPLY OPENJSON(Metrics.DailyMetrics) WITH (
        [Date] DATE '$.Date',
        AvailableSpace INT '$.AvailableSpace',
        TotalUsed INT '$.TotalUsed',
        IsOperational VARCHAR(10) '$.IsOperational',
        Temperature DECIMAL(5,2) '$.Temperature',
        Humidity INT '$.Humidity'
    ) AS DailyMetrics
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p2
AS
BEGIN
    DECLARE @jsonProduction NVARCHAR(MAX) = N'{
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
    -- Query to analyze production metrics
    SELECT 
        ProductionID.PlantCode,
        MachineArr.MachineCode,
        MachineArr.MachineName,
        Metrics.DateTime,
        Metrics.OperationalStatus,
        Metrics.CycleTime,
        Metrics.ProductCount,
        Metrics.PowerConsumption,
        Metrics.OEEScore,
        Metrics.MaintenanceScore
    FROM OPENJSON(@jsonProduction) WITH (
        ProductionID NVARCHAR(MAX) '$.Factory.ProductionID' AS JSON,
        MachineStatusArray NVARCHAR(MAX) '$.Factory.MachineStatusArray' AS JSON
    ) AS Factory
    OUTER APPLY OPENJSON(Factory.ProductionID) WITH (
        PlantCode VARCHAR(10) '$.PlantCode'
    ) AS ProductionID
    OUTER APPLY OPENJSON(Factory.MachineStatusArray) WITH (
        MachineStatus NVARCHAR(MAX) '$.MachineStatus' AS JSON
    ) AS Machines
    OUTER APPLY OPENJSON(Machines.MachineStatus) WITH (
        MachineCode VARCHAR(10) '$.MachineCode',
        MachineName VARCHAR(50) '$.MachineName',
        HourlyMetricsArray NVARCHAR(MAX) '$.HourlyMetricsArray' AS JSON
    ) AS MachineArr
    OUTER APPLY OPENJSON(MachineArr.HourlyMetricsArray) WITH (
        HourlyMetrics NVARCHAR(MAX) '$.HourlyMetrics' AS JSON
    ) AS HourlyData
    OUTER APPLY OPENJSON(HourlyData.HourlyMetrics) WITH (
        DateTime DATETIME '$.DateTime',
        OperationalStatus VARCHAR(20) '$.OperationalStatus',
        CycleTime DECIMAL(10,2) '$.CycleTime',
        ProductCount INT '$.ProductCount',
        PowerConsumption DECIMAL(10,2) '$.PowerConsumption',
        OEEScore DECIMAL(5,2) '$.OEEScore',
        MaintenanceScore DECIMAL(5,2) '$.MaintenanceScore'
    ) AS Metrics
    WHERE Metrics.DateTime IS NOT NULL
    ORDER BY Metrics.DateTime, MachineArr.MachineCode
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p3
AS
BEGIN
    DECLARE @jsonHealthcare NVARCHAR(MAX) = N'{
        "Hospital": {
            "MonitoringSession": {
                "SessionID": "MON20230103001",
                "FacilityCode": "HOSP001",
                "UnitCode": "ICU",
                "FloorNumber": "3",
                "WardCode": "ICU-A",
                "StartTime": "2023-01-03T00:00:00",
                "EndTime": "2023-01-03T23:59:59",
                "StaffShift": "SHIFT_A",
                "MonitoringLevel": "INTENSIVE",
                "AlertProtocol": "STANDARD",
                "DataInterval": "5",
                "ResponsiblePhysician": "DR_SMITH",
                "NursingTeam": "TEAM_A",
                "EmergencyStatus": "NORMAL"
            },
            "SystemConfiguration": {
                "MonitoringDuration": "24",
                "SamplingFrequency": "12",
                "DataRetention": "90",
                "BackupFrequency": "15",
                "AlertThreshold": "CUSTOM",
                "EncryptionLevel": "AES256",
                "ComplianceMode": "HIPAA",
                "DataValidation": "ENABLED"
            },
            "PatientMonitoringArray": {
                "PatientMonitoring": [
                    {
                        "PatientID": "PT100123",
                        "AdmissionID": "ADM20230102003",
                        "Age": "65",
                        "Gender": "M",
                        "RiskLevel": "HIGH",
                        "IsolationStatus": "NONE",
                        "DiagnosisCode": "ICD10-I21.0",
                        "VitalSignsArray": {
                            "VitalSigns": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "HeartRate": "82",
                                    "BloodPressureSystolic": "135",
                                    "BloodPressureDiastolic": "85",
                                    "Temperature": "37.2",
                                    "RespiratoryRate": "16",
                                    "OxygenSaturation": "97",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "2",
                                    "GlucoseLevel": "110",
                                    "EtCO2": "35",
                                    "MAP": "95",
                                    "CVP": "8",
                                    "UrinePH": "6.5",
                                    "UrineOutput": "50",
                                    "FluidBalance": "-120",
                                    "NEWS2Score": "2",
                                    "AlertStatus": "NORMAL",
                                    "InterventionRequired": "false"
                                },
                                {
                                    "DateTime": "2023-01-03T07:00:00",
                                    "HeartRate": "85",
                                    "BloodPressureSystolic": "138",
                                    "BloodPressureDiastolic": "88",
                                    "Temperature": "37.3",
                                    "RespiratoryRate": "18",
                                    "OxygenSaturation": "96",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "3",
                                    "GlucoseLevel": "115",
                                    "EtCO2": "36",
                                    "MAP": "97",
                                    "CVP": "9",
                                    "UrinePH": "6.4",
                                    "UrineOutput": "45",
                                    "FluidBalance": "-150",
                                    "NEWS2Score": "3",
                                    "AlertStatus": "ELEVATED",
                                    "InterventionRequired": "true"
                                },
                                {
                                    "DateTime": "2023-01-03T08:00:00",
                                    "HeartRate": "85",
                                    "BloodPressureSystolic": "138",
                                    "BloodPressureDiastolic": "88",
                                    "Temperature": "37.3",
                                    "RespiratoryRate": "18",
                                    "OxygenSaturation": "96",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "3",
                                    "GlucoseLevel": "115",
                                    "EtCO2": "36",
                                    "MAP": "97",
                                    "CVP": "9",
                                    "UrinePH": "6.4",
                                    "UrineOutput": "45",
                                    "FluidBalance": "-150",
                                    "NEWS2Score": "3",
                                    "AlertStatus": "ELEVATED",
                                    "InterventionRequired": "true"
                                },
                                {
                                    "DateTime": "2023-01-03T09:00:00",
                                    "HeartRate": "85",
                                    "BloodPressureSystolic": "138",
                                    "BloodPressureDiastolic": "88",
                                    "Temperature": "37.3",
                                    "RespiratoryRate": "18",
                                    "OxygenSaturation": "96",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "3",
                                    "GlucoseLevel": "115",
                                    "EtCO2": "36",
                                    "MAP": "97",
                                    "CVP": "9",
                                    "UrinePH": "6.4",
                                    "UrineOutput": "45",
                                    "FluidBalance": "-150",
                                    "NEWS2Score": "3",
                                    "AlertStatus": "ELEVATED",
                                    "InterventionRequired": "true"
                                },
                                {
                                    "DateTime": "2023-01-03T10:00:00",
                                    "HeartRate": "85",
                                    "BloodPressureSystolic": "138",
                                    "BloodPressureDiastolic": "88",
                                    "Temperature": "37.3",
                                    "RespiratoryRate": "18",
                                    "OxygenSaturation": "96",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "3",
                                    "GlucoseLevel": "115",
                                    "EtCO2": "36",
                                    "MAP": "97",
                                    "CVP": "9",
                                    "UrinePH": "6.4",
                                    "UrineOutput": "45",
                                    "FluidBalance": "-150",
                                    "NEWS2Score": "3",
                                    "AlertStatus": "ELEVATED",
                                    "InterventionRequired": "true"
                                },
                                {
                                    "DateTime": "2023-01-03T11:00:00",
                                    "HeartRate": "85",
                                    "BloodPressureSystolic": "138",
                                    "BloodPressureDiastolic": "88",
                                    "Temperature": "37.3",
                                    "RespiratoryRate": "18",
                                    "OxygenSaturation": "96",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "3",
                                    "GlucoseLevel": "115",
                                    "EtCO2": "36",
                                    "MAP": "97",
                                    "CVP": "9",
                                    "UrinePH": "6.4",
                                    "UrineOutput": "45",
                                    "FluidBalance": "-150",
                                    "NEWS2Score": "3",
                                    "AlertStatus": "ELEVATED",
                                    "InterventionRequired": "true"
                                },
                                {
                                    "DateTime": "2023-01-03T12:00:00",
                                    "HeartRate": "85",
                                    "BloodPressureSystolic": "138",
                                    "BloodPressureDiastolic": "88",
                                    "Temperature": "37.3",
                                    "RespiratoryRate": "18",
                                    "OxygenSaturation": "96",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "3",
                                    "GlucoseLevel": "115",
                                    "EtCO2": "36",
                                    "MAP": "97",
                                    "CVP": "9",
                                    "UrinePH": "6.4",
                                    "UrineOutput": "45",
                                    "FluidBalance": "-150",
                                    "NEWS2Score": "3",
                                    "AlertStatus": "ELEVATED",
                                    "InterventionRequired": "true"
                                }
                            ]
                        }
                    },
                    {
                        "PatientID": "PT100124",
                        "AdmissionID": "ADM20230102004",
                        "Age": "45",
                        "Gender": "F",
                        "RiskLevel": "MEDIUM",
                        "IsolationStatus": "CONTACT",
                        "DiagnosisCode": "ICD10-J18.9",
                        "VitalSignsArray": {
                            "VitalSigns": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "HeartRate": "75",
                                    "BloodPressureSystolic": "122",
                                    "BloodPressureDiastolic": "78",
                                    "Temperature": "38.5",
                                    "RespiratoryRate": "20",
                                    "OxygenSaturation": "94",
                                    "ConsciousnessLevel": "ALERT",
                                    "PainScore": "4",
                                    "GlucoseLevel": "105",
                                    "EtCO2": "38",
                                    "MAP": "92",
                                    "CVP": "7",
                                    "UrinePH": "6.2",
                                    "UrineOutput": "40",
                                    "FluidBalance": "-200",
                                    "NEWS2Score": "4",
                                    "AlertStatus": "ELEVATED",
                                    "InterventionRequired": "true"
                                }
                            ]
                        }
                    }
                ]
            },
            "MedicalDeviceArray": {
                "MedicalDevice": [
                    {
                        "DeviceID": "VEN001",
                        "DeviceType": "VENTILATOR",
                        "Manufacturer": "MEDTECH",
                        "Model": "VENT-2000",
                        "LastCalibration": "2022-12-15",
                        "NextCalibration": "2023-03-15",
                        "AssignedPatient": "PT100123",
                        "MetricsArray": {
                            "Metrics": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "Mode": "SIMV",
                                    "TidalVolume": "450",
                                    "RespiratoryRate": "16",
                                    "PEEP": "5",
                                    "FiO2": "40",
                                    "PIP": "25",
                                    "InspiratoryPressure": "15",
                                    "ExpiratoryPressure": "5",
                                    "MinuteVolume": "7.2",
                                    "AlarmStatus": "NORMAL",
                                    "BatteryLevel": "85",
                                    "MaintenanceStatus": "OK",
                                    "ComplianceScore": "98.5",
                                    "ErrorCount": "0"
                                }
                            ]
                        }
                    },
                    {
                        "DeviceID": "INF001",
                        "DeviceType": "INFUSION_PUMP",
                        "Manufacturer": "MEDTECH",
                        "Model": "INFUS-3000",
                        "LastCalibration": "2022-12-20",
                        "NextCalibration": "2023-03-20",
                        "AssignedPatient": "PT100124",
                        "MetricsArray": {
                            "Metrics": [
                                {
                                    "DateTime": "2023-01-03T06:00:00",
                                    "OperationalStatus": "RUNNING",
                                    "FlowRate": "125",
                                    "TotalVolume": "500",
                                    "InfusedVolume": "125",
                                    "RemainingVolume": "375",
                                    "DrugConcentration": "50",
                                    "DoseRate": "6.25",
                                    "OcclusionPressure": "150",
                                    "BatteryLevel": "90",
                                    "AlarmStatus": "NORMAL",
                                    "MaintenanceStatus": "OK",
                                    "ErrorCount": "0"
                                }
                            ]
                        }
                    }
                ]
            },
            "EnvironmentalMetrics": {
                "RoomTemperature": "21.5",
                "Humidity": "45",
                "AirPressure": "101.3",
                "AirExchangeRate": "12",
                "CO2Level": "450",
                "LightLevel": "250",
                "NoiseLevel": "45",
                "IsolationPressure": "-2.5"
            },
            "QualityMetrics": {
                "InfectionRate": "0.1",
                "HandHygieneCompliance": "95.5",
                "PatientFallRate": "0.0",
                "MedicationErrors": "0",
                "BedOccupancyRate": "85.5",
                "AverageResponseTime": "2.5",
                "PatientSatisfaction": "92.0"
            }
        }
    }'

    -- Query to analyze patient vital signs and device metrics
    SELECT 
        m.SessionID,
        p.PatientID,
        p.DiagnosisCode,
        v.DateTime,
        v.HeartRate,
        v.BloodPressureSystolic,
        v.BloodPressureDiastolic,
        v.Temperature,
        v.OxygenSaturation,
        v.NEWS2Score,
        v.AlertStatus,
        d.DeviceID,
        d.DeviceType,
        dm.OperationalStatus,
        dm.AlarmStatus
    FROM OPENJSON(@jsonHealthcare) WITH (
        MonitoringSession NVARCHAR(MAX) '$.Hospital.MonitoringSession' AS JSON,
        PatientMonitoringArray NVARCHAR(MAX) '$.Hospital.PatientMonitoringArray' AS JSON,
        MedicalDeviceArray NVARCHAR(MAX) '$.Hospital.MedicalDeviceArray' AS JSON
    ) AS Hospital
    OUTER APPLY OPENJSON(Hospital.MonitoringSession) WITH (
        SessionID VARCHAR(20) '$.SessionID'
    ) AS m
    OUTER APPLY OPENJSON(Hospital.PatientMonitoringArray) WITH (
        PatientMonitoring NVARCHAR(MAX) '$.PatientMonitoring' AS JSON
    ) AS Patients
    OUTER APPLY OPENJSON(Patients.PatientMonitoring) WITH (
        PatientID VARCHAR(10) '$.PatientID',
        DiagnosisCode VARCHAR(20) '$.DiagnosisCode',
        VitalSignsArray NVARCHAR(MAX) '$.VitalSignsArray' AS JSON
    ) AS p
    OUTER APPLY OPENJSON(p.VitalSignsArray) WITH (
        VitalSigns NVARCHAR(MAX) '$.VitalSigns' AS JSON
    ) AS Vitals
    OUTER APPLY OPENJSON(Vitals.VitalSigns) WITH (
        DateTime DATETIME '$.DateTime',
        HeartRate INT '$.HeartRate',
        BloodPressureSystolic INT '$.BloodPressureSystolic',
        BloodPressureDiastolic INT '$.BloodPressureDiastolic',
        Temperature DECIMAL(4,1) '$.Temperature',
        OxygenSaturation INT '$.OxygenSaturation',
        NEWS2Score INT '$.NEWS2Score',
        AlertStatus VARCHAR(20) '$.AlertStatus'
    ) AS v
    OUTER APPLY OPENJSON(Hospital.MedicalDeviceArray) WITH (
        MedicalDevice NVARCHAR(MAX) '$.MedicalDevice' AS JSON
    ) AS Devices
    OUTER APPLY OPENJSON(Devices.MedicalDevice) WITH (
        DeviceID VARCHAR(10) '$.DeviceID',
        DeviceType VARCHAR(20) '$.DeviceType',
        AssignedPatient VARCHAR(10) '$.AssignedPatient',
        MetricsArray NVARCHAR(MAX) '$.MetricsArray' AS JSON
    ) AS d
    OUTER APPLY OPENJSON(d.MetricsArray) WITH (
        Metrics NVARCHAR(MAX) '$.Metrics' AS JSON
    ) AS DeviceMetrics
    OUTER APPLY OPENJSON(DeviceMetrics.Metrics) WITH (
        DateTime DATETIME '$.DateTime',
        OperationalStatus VARCHAR(20) '$.OperationalStatus',
        AlarmStatus VARCHAR(20) '$.AlarmStatus'
    ) AS dm
    WHERE p.PatientID = d.AssignedPatient
    AND v.DateTime = dm.DateTime
    ORDER BY v.DateTime, p.PatientID
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p4
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'{
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

    SELECT * FROM OPENJSON(@json, '$') with (name nvarchar(max) '$' AS JSON)
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p5
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'{
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

    SELECT * FROM OPENJSON(@json, '$') with (name sys.nvarchar(max) '$' AS JSON)
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p6
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'{
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

    SELECT * FROM OPENJSON(@json, '$') with (name nvarchar(max) '$.Factory' AS JSON)
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p7
    @jsonInventory NVARCHAR(MAX)
AS
BEGIN
    SELECT 
        WarehouseID.FacilityCode AS FacilityCode,
        StorageArr.StorageCode AS Storage_Code,
        [Date] AS Metric_Date,
        AvailableSpace AS Available_Space,
        TotalUsed AS Total_Used,
        IsOperational AS Is_Operational,
        Temperature AS Storage_Temp,
        Humidity AS Storage_Humidity
    FROM OPENJSON(@jsonInventory) WITH (
        WarehouseID NVARCHAR(MAX) '$.Warehouse.WarehouseID' AS JSON,
        StorageTypeArray NVARCHAR(MAX) '$.Warehouse.StorageTypeArray' AS JSON
    ) AS [Warehouse]
    OUTER APPLY OPENJSON([Warehouse].WarehouseID) WITH (
        FacilityCode VARCHAR(15) '$.FacilityCode'
    ) AS WarehouseID
    OUTER APPLY OPENJSON([Warehouse].StorageTypeArray) WITH (
        StorageType NVARCHAR(MAX) '$.StorageType' AS JSON
    ) AS Storage
    OUTER APPLY OPENJSON(Storage.StorageType) WITH (
        StorageCode VARCHAR(6) '$.StorageCode',
        DailyMetricsArray NVARCHAR(MAX) '$.DailyMetricsArray' AS JSON
    ) AS StorageArr
    OUTER APPLY OPENJSON(StorageArr.DailyMetricsArray) WITH (
        DailyMetrics NVARCHAR(MAX) '$.DailyMetrics' AS JSON
    ) AS Metrics
    OUTER APPLY OPENJSON(Metrics.DailyMetrics) WITH (
        [Date] DATE '$.Date',
        AvailableSpace INT '$.AvailableSpace',
        TotalUsed INT '$.TotalUsed',
        IsOperational VARCHAR(10) '$.IsOperational',
        Temperature DECIMAL(5,2) '$.Temperature',
        Humidity INT '$.Humidity'
    ) AS DailyMetrics
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p8
    @jsonProduction NVARCHAR(MAX) 
AS
BEGIN
    SELECT 
        ProductionID.PlantCode,
        MachineArr.MachineCode,
        MachineArr.MachineName,
        Metrics.DateTime,
        Metrics.OperationalStatus,
        Metrics.CycleTime,
        Metrics.ProductCount,
        Metrics.PowerConsumption,
        Metrics.OEEScore,
        Metrics.MaintenanceScore
    FROM OPENJSON(@jsonProduction) WITH (
        ProductionID NVARCHAR(MAX) '$.Factory.ProductionID' AS JSON,
        MachineStatusArray NVARCHAR(MAX) '$.Factory.MachineStatusArray' AS JSON
    ) AS Factory
    OUTER APPLY OPENJSON(Factory.ProductionID) WITH (
        PlantCode VARCHAR(10) '$.PlantCode'
    ) AS ProductionID
    OUTER APPLY OPENJSON(Factory.MachineStatusArray) WITH (
        MachineStatus NVARCHAR(MAX) '$.MachineStatus' AS JSON
    ) AS Machines
    OUTER APPLY OPENJSON(Machines.MachineStatus) WITH (
        MachineCode VARCHAR(10) '$.MachineCode',
        MachineName VARCHAR(50) '$.MachineName',
        HourlyMetricsArray NVARCHAR(MAX) '$.HourlyMetricsArray' AS JSON
    ) AS MachineArr
    OUTER APPLY OPENJSON(MachineArr.HourlyMetricsArray) WITH (
        HourlyMetrics NVARCHAR(MAX) '$.HourlyMetrics' AS JSON
    ) AS HourlyData
    OUTER APPLY OPENJSON(HourlyData.HourlyMetrics) WITH (
        DateTime DATETIME '$.DateTime',
        OperationalStatus VARCHAR(20) '$.OperationalStatus',
        CycleTime DECIMAL(10,2) '$.CycleTime',
        ProductCount INT '$.ProductCount',
        PowerConsumption DECIMAL(10,2) '$.PowerConsumption',
        OEEScore DECIMAL(5,2) '$.OEEScore',
        MaintenanceScore DECIMAL(5,2) '$.MaintenanceScore'
    ) AS Metrics
    WHERE Metrics.DateTime IS NOT NULL
    ORDER BY Metrics.DateTime, MachineArr.MachineCode
END;
GO


CREATE PROCEDURE BABEL_5054_vu_prepare_p9
    @json NVARCHAR(MAX)
AS
BEGIN
    SELECT * FROM OPENJSON(@json, '$') with (name nvarchar(max) '$.Factory' AS JSON)
END;
GO


CREATE VIEW BABEL_5054_vu_prepare_v1
AS
    SELECT * FROM OPENJSON(N'{
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
                    },
                    {
                        "DateTime": "2023-01-03T08:00:00",
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
    , '$') with (name nvarchar(max) '$.Factory' AS JSON);
GO


CREATE VIEW BABEL_5054_vu_prepare_v2
AS
    SELECT 
        ProductionID.PlantCode,
        MachineArr.MachineCode,
        MachineArr.MachineName,
        Metrics.DateTime,
        Metrics.OperationalStatus,
        Metrics.CycleTime,
        Metrics.ProductCount,
        Metrics.PowerConsumption,
        Metrics.OEEScore,
        Metrics.MaintenanceScore
    FROM OPENJSON(N'{
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
    }') WITH (
        ProductionID NVARCHAR(MAX) '$.Factory.ProductionID' AS JSON,
        MachineStatusArray NVARCHAR(MAX) '$.Factory.MachineStatusArray' AS JSON
    ) AS Factory
    OUTER APPLY OPENJSON(Factory.ProductionID) WITH (
        PlantCode VARCHAR(10) '$.PlantCode'
    ) AS ProductionID
    OUTER APPLY OPENJSON(Factory.MachineStatusArray) WITH (
        MachineStatus NVARCHAR(MAX) '$.MachineStatus' AS JSON
    ) AS Machines
    OUTER APPLY OPENJSON(Machines.MachineStatus) WITH (
        MachineCode VARCHAR(10) '$.MachineCode',
        MachineName VARCHAR(50) '$.MachineName',
        HourlyMetricsArray NVARCHAR(MAX) '$.HourlyMetricsArray' AS JSON
    ) AS MachineArr
    OUTER APPLY OPENJSON(MachineArr.HourlyMetricsArray) WITH (
        HourlyMetrics NVARCHAR(MAX) '$.HourlyMetrics' AS JSON
    ) AS HourlyData
    OUTER APPLY OPENJSON(HourlyData.HourlyMetrics) WITH (
        DateTime DATETIME '$.DateTime',
        OperationalStatus VARCHAR(20) '$.OperationalStatus',
        CycleTime DECIMAL(10,2) '$.CycleTime',
        ProductCount INT '$.ProductCount',
        PowerConsumption DECIMAL(10,2) '$.PowerConsumption',
        OEEScore DECIMAL(5,2) '$.OEEScore',
        MaintenanceScore DECIMAL(5,2) '$.MaintenanceScore'
    ) AS Metrics
    WHERE Metrics.DateTime IS NOT NULL
    ORDER BY Metrics.DateTime, MachineArr.MachineCode
GO