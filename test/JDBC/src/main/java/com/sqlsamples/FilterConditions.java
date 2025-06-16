package com.sqlsamples;
import java.util.Set;
import java.util.HashSet;

public class FilterConditions {
    public FilterConditions(final Set<Integer> colsToIgnore) {
        this.colsToIgnore = colsToIgnore;
    }

    private Set<Integer> colsToIgnore;

    public Set<Integer> getColsToIgnore() {
        return this.colsToIgnore;
    }
}