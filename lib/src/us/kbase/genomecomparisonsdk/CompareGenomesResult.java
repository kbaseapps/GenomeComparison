
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
 * <p>Original spec-file type: CompareGenomesResult</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "report_name",
    "report_ref",
    "cg_ref"
})
public class CompareGenomesResult {

    @JsonProperty("report_name")
    private String reportName;
    @JsonProperty("report_ref")
    private String reportRef;
    @JsonProperty("cg_ref")
    private String cgRef;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("report_name")
    public String getReportName() {
        return reportName;
    }

    @JsonProperty("report_name")
    public void setReportName(String reportName) {
        this.reportName = reportName;
    }

    public CompareGenomesResult withReportName(String reportName) {
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

    public CompareGenomesResult withReportRef(String reportRef) {
        this.reportRef = reportRef;
        return this;
    }

    @JsonProperty("cg_ref")
    public String getCgRef() {
        return cgRef;
    }

    @JsonProperty("cg_ref")
    public void setCgRef(String cgRef) {
        this.cgRef = cgRef;
    }

    public CompareGenomesResult withCgRef(String cgRef) {
        this.cgRef = cgRef;
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
        return ((((((((("CompareGenomesResult"+" [reportName=")+ reportName)+", reportRef=")+ reportRef)+", cgRef=")+ cgRef)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
