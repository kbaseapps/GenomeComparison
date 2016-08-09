
package us.kbase.genomecomparisonsdk;

import java.util.HashMap;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: BuildPangenomeResult</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "report_name",
    "report_ref",
    "pg_ref"
})
public class BuildPangenomeResult {

    @JsonProperty("report_name")
    private String reportName;
    @JsonProperty("report_ref")
    private String reportRef;
    @JsonProperty("pg_ref")
    private String pgRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("report_name")
    public String getReportName() {
        return reportName;
    }

    @JsonProperty("report_name")
    public void setReportName(String reportName) {
        this.reportName = reportName;
    }

    public BuildPangenomeResult withReportName(String reportName) {
        this.reportName = reportName;
        return this;
    }

    @JsonProperty("report_ref")
    public String getReportRef() {
        return reportRef;
    }

    @JsonProperty("report_ref")
    public void setReportRef(String reportRef) {
        this.reportRef = reportRef;
    }

    public BuildPangenomeResult withReportRef(String reportRef) {
        this.reportRef = reportRef;
        return this;
    }

    @JsonProperty("pg_ref")
    public String getPgRef() {
        return pgRef;
    }

    @JsonProperty("pg_ref")
    public void setPgRef(String pgRef) {
        this.pgRef = pgRef;
    }

    public BuildPangenomeResult withPgRef(String pgRef) {
        this.pgRef = pgRef;
        return this;
    }

    @JsonAnyGetter
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public String toString() {
        return ((((((((("BuildPangenomeResult"+" [reportName=")+ reportName)+", reportRef=")+ reportRef)+", pgRef=")+ pgRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
