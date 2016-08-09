
package us.kbase.genomecomparison;

import java.util.HashMap;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;


/**
 * <p>Original spec-file type: CompareGenomesParams</p>
 * 
 * 
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@Generated("com.googlecode.jsonschema2pojo")
@JsonPropertyOrder({
    "pangenome_ref",
    "protcomp_ref",
    "output_id",
    "workspace"
})
public class CompareGenomesParams {

    @JsonProperty("pangenome_ref")
    private String pangenomeRef;
    @JsonProperty("protcomp_ref")
    private String protcompRef;
    @JsonProperty("output_id")
    private String outputId;
    @JsonProperty("workspace")
    private String workspace;
    private Map<String, Object> additionalProperties = new HashMap<String, Object>();

    @JsonProperty("pangenome_ref")
    public String getPangenomeRef() {
        return pangenomeRef;
    }

    @JsonProperty("pangenome_ref")
    public void setPangenomeRef(String pangenomeRef) {
        this.pangenomeRef = pangenomeRef;
    }

    public CompareGenomesParams withPangenomeRef(String pangenomeRef) {
        this.pangenomeRef = pangenomeRef;
        return this;
    }

    @JsonProperty("protcomp_ref")
    public String getProtcompRef() {
        return protcompRef;
    }

    @JsonProperty("protcomp_ref")
    public void setProtcompRef(String protcompRef) {
        this.protcompRef = protcompRef;
    }

    public CompareGenomesParams withProtcompRef(String protcompRef) {
        this.protcompRef = protcompRef;
        return this;
    }

    @JsonProperty("output_id")
    public String getOutputId() {
        return outputId;
    }

    @JsonProperty("output_id")
    public void setOutputId(String outputId) {
        this.outputId = outputId;
    }

    public CompareGenomesParams withOutputId(String outputId) {
        this.outputId = outputId;
        return this;
    }

    @JsonProperty("workspace")
    public String getWorkspace() {
        return workspace;
    }

    @JsonProperty("workspace")
    public void setWorkspace(String workspace) {
        this.workspace = workspace;
    }

    public CompareGenomesParams withWorkspace(String workspace) {
        this.workspace = workspace;
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
        return ((((((((((("CompareGenomesParams"+" [pangenomeRef=")+ pangenomeRef)+", protcompRef=")+ protcompRef)+", outputId=")+ outputId)+", workspace=")+ workspace)+", additionalProperties=")+ additionalProperties)+"]");
    }

}
