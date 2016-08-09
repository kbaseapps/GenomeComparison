
package us.kbase.genomecomparison;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: BuildPangenomeParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "genome_refs",
    "genomeset_ref",
    "workspace",
    "output_id"
})
public class BuildPangenomeParams {

    @JsonProperty("genome_refs")
    private List<String> genomeRefs;
    @JsonProperty("genomeset_ref")
    private java.lang.String genomesetRef;
    @JsonProperty("workspace")
    private java.lang.String workspace;
    @JsonProperty("output_id")
    private java.lang.String outputId;
    private Map<java.lang.String, Object> additionalProperties = new HashMap<java.lang.String, Object>();

    @JsonProperty("genome_refs")
    public List<String> getGenomeRefs() {
        return genomeRefs;
    }

    @JsonProperty("genome_refs")
    public void setGenomeRefs(List<String> genomeRefs) {
        this.genomeRefs = genomeRefs;
    }

    public BuildPangenomeParams withGenomeRefs(List<String> genomeRefs) {
        this.genomeRefs = genomeRefs;
        return this;
    }

    @JsonProperty("genomeset_ref")
    public java.lang.String getGenomesetRef() {
        return genomesetRef;
    }

    @JsonProperty("genomeset_ref")
    public void setGenomesetRef(java.lang.String genomesetRef) {
        this.genomesetRef = genomesetRef;
    }

    public BuildPangenomeParams withGenomesetRef(java.lang.String genomesetRef) {
        this.genomesetRef = genomesetRef;
        return this;
    }

    @JsonProperty("workspace")
    public java.lang.String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
    }

    public BuildPangenomeParams withWorkspace(java.lang.String workspace) {
        this.workspace = workspace;
        return this;
    }

    @JsonProperty("output_id")
    public java.lang.String getOutputId() {
        return outputId;
    }

    @JsonProperty("output_id")
    public void setOutputId(java.lang.String outputId) {
        this.outputId = outputId;
    }

    public BuildPangenomeParams withOutputId(java.lang.String outputId) {
        this.outputId = outputId;
        return this;
    }

    @JsonAnyGetter
    public Map<java.lang.String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperties(java.lang.String name, Object value) {
        this.additionalProperties.put(name, value);
    }

    @Override
    public java.lang.String toString() {
        return ((((((((((("BuildPangenomeParams"+" [genomeRefs=")+ genomeRefs)+", genomesetRef=")+ genomesetRef)+", workspace=")+ workspace)+", outputId=")+ outputId)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
