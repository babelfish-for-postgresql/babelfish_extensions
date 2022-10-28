package com.sqlsamples;

import java.util.*;

import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

public class Statistics {
    DescriptiveStatistics descriptiveStatistics;
    static ArrayList<Long> exec_times = new ArrayList<>();
    static long curr_exec_time = 0L;
    static long sla = 0L;
    public Statistics(double[] values) { 
        descriptiveStatistics = new DescriptiveStatistics(values);
    }
    
    public double mean() {
        return descriptiveStatistics.getMean();
    }
    
    public double median() {
        return descriptiveStatistics.getPercentile(50);
    }
    
    public double stddev() {
        return descriptiveStatistics.getStandardDeviation();
    }
    
    public double minimum() {
        return descriptiveStatistics.getMin();
    }

    public double maximum() {
        return descriptiveStatistics.getMax();
    }
}
