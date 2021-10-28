package com.sqlsamples;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;

import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;

public class ExportResults {

    public static void createCSVFile(String CSVfileName, HashMap<String, Statistics> statisticsHashMap) {
        
        String[] HEADERS = { "URI", "Min exec time", "Max exec time", "Mean exec time", "Median exec time", "Std. dev"};

        try {
            FileWriter out = new FileWriter(CSVfileName + ".csv");
            CSVPrinter printer = new CSVPrinter(out, CSVFormat.DEFAULT.withHeader(HEADERS));
            statisticsHashMap.forEach((URI, statistics) -> {
                try {
                    printer.printRecord(URI, statistics.minimum(), statistics.maximum(), statistics.mean(), statistics.median(), statistics.stddev());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
            
            printer.close();
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
